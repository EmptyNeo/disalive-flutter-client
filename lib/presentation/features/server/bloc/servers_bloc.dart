import 'dart:async';
import 'dart:math' as math;

import 'package:disalive/app/di/di.dart';
import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:equatable/equatable.dart';

part 'servers_event.dart';
part 'servers_state.dart';

class ServersBloc extends Bloc<ServersEvent, ServersState> {
  final ServerRepository _serverRepository;
  final WsEventBus _eventBus;
  StreamSubscription<WsEvent>? _subscription;
  StreamSubscription<WsEvent>? _memberSubscription;
  final Map<(int, int), int> _lastReadByChannel = {};
  final List<ServersEvent> _changesDuringLoad = [];
  bool _isLoading = false;

  ServersBloc(this._serverRepository, this._eventBus)
    : super(ServersInitial()) {
    on<GetServers>(_onGetServers);
    on<SelectServer>((event, emit) {
      _serverRepository.selectServer(event.serverId);
      emit(_loaded(_serverRepository.getCached()));
    });
    on<ServerUpserted>(_onServerUpserted);
    on<ServerRemoved>(_onServerRemoved);
    on<ServerMemberUpdated>(_onServerMemberUpdated);
    setupListeners();
  }

  void setupListeners() {
    _subscription?.cancel();
    _subscription = _eventBus.subscribeToTable(
      table: 'Servers',
      onData: (event) {
        if (event.action == ActionType.create ||
            event.action == ActionType.update) {
          final rawServer = event.data['server'];
          if (rawServer is! Map) return;

          final serverData = Map<String, dynamic>.from(rawServer);
          final id = DataParser.parseInt(
            serverData['id'] ??
                event.data['serverId'] ??
                event.data['entityId'],
          );
          if (id == null) return;

          serverData['id'] = id;
          add(ServerUpserted(serverData));
        } else if (event.action == ActionType.delete) {
          final id = DataParser.parseInt(
            event.data['serverId'] ??
                event.data['entityId'] ??
                event.data['id'],
          );
          if (id != null) add(ServerRemoved(id));
        }
      },
    );
    _memberSubscription?.cancel();
    _memberSubscription = _eventBus.subscribe(
      table: 'ChatMembers',
      action: ActionType.update,
      onData: (event) {
        if (event.data['entityType'] != EntityType.server.value ||
            !(DataParser.parseBool(event.data['isSelf']) ?? event.isSelf)) {
          return;
        }
        final serverId = DataParser.parseInt(event.data['entityId']);
        final rawMember = event.data['member'];
        if (serverId == null || rawMember is! Map) return;
        final member = Map<String, dynamic>.from(rawMember);
        final chatId = DataParser.parseInt(event.data['chatId']);
        final readId = DataParser.parseInt(member['lastIdReadMessage']);
        var readReduction = 0;
        if (chatId != null &&
            readId != null &&
            sl.isRegistered<ChannelServerRepository>()) {
          final channelRepository = sl<ChannelServerRepository>();
          for (final channel in channelRepository.getCached(serverId)) {
            if (channel.chatId != chatId) continue;
            final key = (serverId, chatId);
            final previousRead =
                _lastReadByChannel[key] ?? channel.lastIdReadMessage ?? 0;
            if (readId > previousRead) {
              readReduction = math.min(
                channel.newMessagesCount,
                readId - previousRead,
              );
              _lastReadByChannel[key] = readId;
            }
            break;
          }
        }
        add(
          ServerMemberUpdated(
            serverId,
            muted: DataParser.parseBool(member['muted']),
            readReduction: readReduction,
            newMessagesCount: DataParser.parseInt(
              event.data['newMessagesCount'],
            ),
          ),
        );
      },
    );
  }

  ServersLoaded _loaded(List<Server> servers) => ServersLoaded(
    List<Server>.unmodifiable(servers),
    selectedServerId: _serverRepository.selectedServerId,
  );

  Future<void> _onGetServers(
    GetServers event,
    Emitter<ServersState> emit,
  ) async {
    if (_isLoading) return;
    _isLoading = true;
    _changesDuringLoad.clear();

    final cached = _serverRepository.getCached();
    if (cached.isNotEmpty) {
      emit(_loaded(cached));
    } else {
      emit(ServersLoading());
    }

    final result = await _serverRepository.get();
    _isLoading = false;

    result.fold(
      (failure) {
        final current = _serverRepository.getCached();
        if (current.isEmpty) {
          emit(ServersFailure(failure));
        } else {
          emit(_loaded(current));
        }
      },
      (loaded) {
        final servers = List<Server>.from(loaded);
        for (final change in _changesDuringLoad) {
          if (change is ServerUpserted) {
            _applyUpsert(servers, change.serverData);
          } else if (change is ServerRemoved) {
            servers.removeWhere((server) => server.id == change.id);
          } else if (change is ServerMemberUpdated) {
            _applyMemberUpdate(servers, change);
          }
        }
        _serverRepository.updateCache(servers);
        emit(_loaded(servers));
      },
    );
    _changesDuringLoad.clear();
  }

  void _onServerUpserted(ServerUpserted event, Emitter<ServersState> emit) {
    if (_isLoading) _changesDuringLoad.add(event);

    final servers = List<Server>.from(_serverRepository.getCached());
    _applyUpsert(servers, event.serverData);
    _serverRepository.updateCache(servers);
    emit(_loaded(servers));
  }

  void _applyUpsert(List<Server> servers, Map<String, dynamic> serverData) {
    final id = DataParser.parseInt(serverData['id']);
    if (id == null) return;

    final index = servers.indexWhere((item) => item.id == id);
    final cached = index == -1 ? null : servers[index];
    final server = Server.fromMap({
      if (cached != null) ...cached.toMap(),
      ...serverData,
    });

    if (index == -1) {
      servers.add(server);
    } else {
      servers[index] = server;
    }
  }

  void _onServerRemoved(ServerRemoved event, Emitter<ServersState> emit) {
    if (_isLoading) _changesDuringLoad.add(event);
    if (_serverRepository.selectedServerId == event.id) {
      _serverRepository.selectServer(null);
    }

    final servers = List<Server>.from(_serverRepository.getCached())
      ..removeWhere((server) => server.id == event.id);
    _serverRepository.updateCache(servers);
    emit(_loaded(servers));
  }

  void _onServerMemberUpdated(
    ServerMemberUpdated event,
    Emitter<ServersState> emit,
  ) {
    if (_isLoading) _changesDuringLoad.add(event);
    final servers = List<Server>.from(_serverRepository.getCached());
    if (!_applyMemberUpdate(servers, event)) return;
    _serverRepository.updateCache(servers);
    emit(_loaded(servers));
  }

  bool _applyMemberUpdate(List<Server> servers, ServerMemberUpdated event) {
    final index = servers.indexWhere((server) => server.id == event.serverId);
    if (index < 0) return false;
    final previous = servers[index];
    final count = event.newMessagesCount != null
        ? math.max(0, event.newMessagesCount!)
        : event.readReduction > 0
        ? math.max(0, (previous.newMessagesCount ?? 0) - event.readReduction)
        : previous.newMessagesCount;
    servers[index] = previous.copyWith(
      muted: event.muted,
      newMessagesCount: count,
    );
    return true;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _memberSubscription?.cancel();
    _lastReadByChannel.clear();
    _serverRepository.clear();
    await super.close();
  }
}

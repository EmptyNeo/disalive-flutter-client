import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:equatable/equatable.dart';

part 'channel_server_event.dart';
part 'channel_server_state.dart';

class ChannelServerBloc extends Bloc<ChannelServerEvent, ChannelServerState> {
  final ChannelServerRepository _repository;
  final WsEventBus _eventBus;
  StreamSubscription<WsEvent>? _subscription;
  StreamSubscription<WsEvent>? _memberSubscription;
  final List<ChannelServerEvent> _changesDuringLoad = [];
  int? _serverId;
  int _loadGeneration = 0;
  bool _isLoading = false;

  ChannelServerBloc(this._repository, this._eventBus)
    : super(ChannelServerInitial()) {
    on<GetServerChannels>(_onGetServerChannels);
    on<ServerChannelUpserted>(_onUpserted);
    on<ServerChannelRemoved>(_onRemoved);
    on<ServerChannelReadUpdated>(_onReadUpdated);
    setupListeners();
  }

  void setupListeners() {
    _subscription?.cancel();
    _subscription = _eventBus.subscribeToTable(
      table: 'ChannelsServer',
      onData: (event) {
        final rawChannel = event.data['channel'];
        final channelData = rawChannel is Map
            ? Map<String, dynamic>.from(rawChannel)
            : <String, dynamic>{};
        final serverId = DataParser.parseInt(
          event.data['serverId'] ??
              event.data['entityId'] ??
              channelData['serverId'],
        );
        if (serverId == null || serverId != _serverId) return;

        if (event.action == ActionType.create ||
            event.action == ActionType.update) {
          final id = DataParser.parseInt(
            channelData['id'] ?? event.data['channelId'],
          );
          if (id == null || rawChannel is! Map) return;
          channelData['id'] = id;
          channelData['serverId'] = serverId;
          add(ServerChannelUpserted(serverId, channelData));
        } else if (event.action == ActionType.delete) {
          final id = DataParser.parseInt(
            event.data['channelId'] ?? channelData['id'],
          );
          if (id != null) add(ServerChannelRemoved(serverId, id));
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
        final chatId = DataParser.parseInt(event.data['chatId']);
        final rawMember = event.data['member'];
        if (serverId == null ||
            serverId != _serverId ||
            chatId == null ||
            rawMember is! Map) {
          return;
        }
        final member = Map<String, dynamic>.from(rawMember);
        final readId = DataParser.parseInt(member['lastIdReadMessage']);
        if (readId == null) return;
        add(
          ServerChannelReadUpdated(
            serverId,
            chatId,
            readId,
            newMessagesCount: DataParser.parseInt(member['newMessagesCount']),
          ),
        );
      },
    );
  }

  Future<void> _onGetServerChannels(
    GetServerChannels event,
    Emitter<ChannelServerState> emit,
  ) async {
    if (_isLoading && _serverId == event.serverId) return;
    _serverId = event.serverId;
    _isLoading = true;
    final generation = ++_loadGeneration;
    _changesDuringLoad.clear();

    final cached = _repository.getCached(event.serverId);
    if (cached.isNotEmpty) {
      emit(ServerChannelsLoaded(event.serverId, List.unmodifiable(cached)));
    } else {
      emit(ServerChannelsLoading(event.serverId));
    }

    final result = await _repository.get(event.serverId);
    if (generation != _loadGeneration || isClosed) return;
    _isLoading = false;

    result.fold(
      (failure) {
        final current = _repository.getCached(event.serverId);
        if (current.isEmpty) {
          emit(ServerChannelsFailure(event.serverId, failure));
        } else {
          emit(
            ServerChannelsLoaded(event.serverId, List.unmodifiable(current)),
          );
        }
      },
      (loaded) {
        final channels = List<ChannelServer>.from(loaded);
        for (final change in _changesDuringLoad) {
          if (change is ServerChannelUpserted) {
            _applyUpsert(channels, change.channelData);
          } else if (change is ServerChannelRemoved) {
            channels.removeWhere((channel) => channel.id == change.id);
          } else if (change is ServerChannelReadUpdated) {
            _applyReadUpdate(channels, change);
          }
        }
        _repository.updateCache(event.serverId, channels);
        emit(ServerChannelsLoaded(event.serverId, List.unmodifiable(channels)));
      },
    );
    _changesDuringLoad.clear();
  }

  void _onUpserted(
    ServerChannelUpserted event,
    Emitter<ChannelServerState> emit,
  ) {
    if (event.serverId != _serverId) return;
    if (_isLoading) _changesDuringLoad.add(event);

    final channels = List<ChannelServer>.from(
      _repository.getCached(event.serverId),
    );
    _applyUpsert(channels, event.channelData);
    _repository.updateCache(event.serverId, channels);
    emit(ServerChannelsLoaded(event.serverId, List.unmodifiable(channels)));
  }

  void _applyUpsert(List<ChannelServer> channels, Map<String, dynamic> data) {
    final id = DataParser.parseInt(data['id']);
    if (id == null) return;
    final index = channels.indexWhere((item) => item.id == id);
    final previous = index < 0 ? null : channels[index];
    final channel = ChannelServer.fromMap({
      if (previous != null) ...previous.toMap(),
      ...data,
    });
    if (index < 0) {
      channels.add(channel);
    } else {
      channels[index] = channel;
    }
  }

  void _onRemoved(
    ServerChannelRemoved event,
    Emitter<ChannelServerState> emit,
  ) {
    if (event.serverId != _serverId) return;
    if (_isLoading) _changesDuringLoad.add(event);

    final channels = List<ChannelServer>.from(
      _repository.getCached(event.serverId),
    )..removeWhere((channel) => channel.id == event.id);
    _repository.updateCache(event.serverId, channels);
    emit(ServerChannelsLoaded(event.serverId, List.unmodifiable(channels)));
  }

  void _onReadUpdated(
    ServerChannelReadUpdated event,
    Emitter<ChannelServerState> emit,
  ) {
    if (event.serverId != _serverId) return;
    if (_isLoading) _changesDuringLoad.add(event);

    final channels = List<ChannelServer>.from(
      _repository.getCached(event.serverId),
    );
    if (!_applyReadUpdate(channels, event)) return;
    _repository.updateCache(event.serverId, channels);
    emit(ServerChannelsLoaded(event.serverId, List.unmodifiable(channels)));
  }

  bool _applyReadUpdate(
    List<ChannelServer> channels,
    ServerChannelReadUpdated event,
  ) {
    final index = channels.indexWhere((item) => item.chatId == event.chatId);
    if (index < 0) return false;
    final previous = channels[index];
    final currentRead = previous.lastIdReadMessage ?? 0;
    if (event.lastIdReadMessage < currentRead) return false;
    final unread =
        event.newMessagesCount ??
        math.max(
          0,
          previous.newMessagesCount - (event.lastIdReadMessage - currentRead),
        );
    channels[index] = ChannelServer.fromMap({
      ...previous.toMap(),
      'lastIdReadMessage': event.lastIdReadMessage,
      'newMessagesCount': math.max(0, unread),
    });
    return true;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _memberSubscription?.cancel();
    if (_serverId != null) _repository.clear(_serverId);
    await super.close();
  }
}

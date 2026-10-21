import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/server_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/server/servers_sidebar.dart';
import 'package:disalive/presentation/features/server/widgets/server_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeServerRepository implements ServerRepository {
  List<Server> servers = [];
  int? _selectedServerId;

  @override
  int? get selectedServerId => _selectedServerId;

  @override
  Server? get selectedServer =>
      _selectedServerId == null ? null : getByIdCached(_selectedServerId!);

  @override
  void selectServer(int? serverId) => _selectedServerId = serverId;

  @override
  Future<Either<Failure, List<Server>>> get({
    bool isPublic = false,
    ServerType? category,
    String? query,
  }) async {
    servers = [
      const Server(id: 1, name: 'Original', fkOwner: 9, newMessagesCount: 5),
    ];
    return Right(List<Server>.from(servers));
  }

  @override
  List<Server> getCached() => servers;

  @override
  Server? getByIdCached(int id) {
    for (final server in servers) {
      if (server.id == id) return server;
    }
    return null;
  }

  @override
  void updateCache(List<Server> updated) {
    servers = List<Server>.from(updated);
  }

  @override
  void clear() {
    servers = [];
    _selectedServerId = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DelayedServerRepository extends _FakeServerRepository {
  final Completer<void> release = Completer<void>();

  @override
  Future<Either<Failure, List<Server>>> get({
    bool isPublic = false,
    ServerType? category,
    String? query,
  }) async {
    await release.future;
    servers = [const Server(id: 1, name: 'Stale response')];
    return Right(List<Server>.from(servers));
  }
}

class _CachedChannels implements ChannelServerRepository {
  @override
  List<ChannelServer> getCached(int serverId) => const [
    ChannelServer(
      id: 10,
      serverId: 1,
      chatId: 90,
      lastIdReadMessage: 40,
      newMessagesCount: 4,
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('new channel message increments server unread count', () async {
    await sl.reset();
    sl.registerSingleton<ChannelServerRepository>(_CachedChannels());
    final repository = _FakeServerRepository();
    final bus = WsEventBus();
    final bloc = ServersBloc(repository, bus);
    bloc.add(const GetServers());
    await bloc.stream.firstWhere((state) => state is ServersLoaded);

    final added = bloc.stream.firstWhere(
      (state) =>
          state is ServersLoaded && state.servers.first.newMessagesCount == 6,
    );
    bus.dispatch(
      WsEvent(
        table: 'Message',
        action: ActionType.create,
        data: {
          'message': {'id': 50, 'chatId': 90},
        },
        isSelf: false,
      ),
    );
    await added;

    final read = bloc.stream.firstWhere(
      (state) =>
          state is ServersLoaded && state.servers.first.newMessagesCount == 2,
    );
    bus.dispatch(
      WsEvent(
        table: 'ChatMembers',
        action: ActionType.update,
        data: {
          'entityId': 1,
          'entityType': 'server',
          'chatId': 90,
          'isSelf': true,
          'member': {'lastIdReadMessage': 50},
        },
        isSelf: true,
      ),
    );
    await read;
    await bloc.close();
    bus.dispose();
    await sl.reset();
  });

  test('server member update changes mute and reduces unread count', () async {
    await sl.reset();
    sl.registerSingleton<ChannelServerRepository>(_CachedChannels());
    final repository = _FakeServerRepository();
    final bus = WsEventBus();
    final bloc = ServersBloc(repository, bus);
    bloc.add(const GetServers());
    await bloc.stream.firstWhere((state) => state is ServersLoaded);

    final updated = bloc.stream.firstWhere(
      (state) => state is ServersLoaded && state.servers.first.muted == true,
    );
    bus.dispatch(
      WsEvent(
        table: 'ChatMembers',
        action: ActionType.update,
        data: {
          'entityId': 1,
          'entityType': 'server',
          'chatId': 90,
          'isSelf': true,
          'member': {'lastIdReadMessage': 42, 'muted': true},
        },
        isSelf: true,
      ),
    );
    await updated;
    expect(repository.getByIdCached(1)?.newMessagesCount, 3);
    expect(repository.getByIdCached(1)?.muted, isTrue);

    final unmuted = bloc.stream.firstWhere(
      (state) => state is ServersLoaded && state.servers.first.muted == false,
    );
    bus.dispatch(
      WsEvent(
        table: 'ChatMembers',
        action: ActionType.update,
        data: {
          'entityId': 1,
          'entityType': 'server',
          'isSelf': true,
          'member': {'muted': false},
        },
        isSelf: true,
      ),
    );
    await unmuted;
    expect(repository.getByIdCached(1)?.newMessagesCount, 3);

    await bloc.close();
    bus.dispose();
    await sl.reset();
  });

  test(
    'ServersBloc loads and applies create, partial update and delete',
    () async {
      final repository = _FakeServerRepository();
      final bus = WsEventBus();
      final bloc = ServersBloc(repository, bus);

      final initialLoad = bloc.stream.firstWhere(
        (state) => state is ServersLoaded,
      );
      bloc.add(const GetServers());
      await initialLoad;
      expect(repository.getByIdCached(1)?.name, 'Original');

      final selected = bloc.stream.firstWhere(
        (state) => state is ServersLoaded && state.selectedServerId == 1,
      );
      bloc.add(const SelectServer(1));
      await selected;
      expect(repository.selectedServer?.name, 'Original');

      final created = bloc.stream.firstWhere(
        (state) => state is ServersLoaded && state.servers.length == 2,
      );
      bus.dispatch(
        WsEvent(
          table: 'Servers',
          action: ActionType.create,
          data: {
            'server': {'id': 2, 'name': 'New', 'category': 'MUSIC'},
            'entityId': 2,
          },
          isSelf: true,
        ),
      );
      await created;
      expect(repository.getByIdCached(2)?.category, ServerType.music);

      final updated = bloc.stream.firstWhere(
        (state) =>
            state is ServersLoaded &&
            state.servers.any(
              (server) => server.id == 1 && server.name == 'Changed',
            ),
      );
      bus.dispatch(
        WsEvent(
          table: 'Servers',
          action: ActionType.update,
          data: {
            'serverId': 1,
            'server': {
              'name': 'Changed',
              'fkMainChannel': null,
              'category': 'GAMES',
            },
          },
          isSelf: false,
        ),
      );
      await updated;
      expect(repository.getByIdCached(1)?.fkOwner, 9);
      expect(repository.getByIdCached(1)?.category, ServerType.games);

      final selectedNew = bloc.stream.firstWhere(
        (state) => state is ServersLoaded && state.selectedServerId == 2,
      );
      bloc.add(const SelectServer(2));
      await selectedNew;
      expect(repository.selectedServer?.name, 'New');

      final removed = bloc.stream.firstWhere(
        (state) => state is ServersLoaded && state.servers.length == 1,
      );
      bus.dispatch(
        WsEvent(
          table: 'Servers',
          action: ActionType.delete,
          data: {'entityId': '2'},
          isSelf: false,
        ),
      );
      await removed;
      expect(repository.getByIdCached(2), isNull);
      expect(repository.selectedServerId, isNull);

      await bloc.close();
      bus.dispose();
    },
  );

  test(
    'WebSocket changes received during loading survive HTTP response',
    () async {
      final repository = _DelayedServerRepository();
      final bus = WsEventBus();
      final bloc = ServersBloc(repository, bus);

      final loading = bloc.stream.firstWhere(
        (state) => state is ServersLoading,
      );
      bloc.add(const GetServers());
      await loading;

      final websocketUpdate = bloc.stream.firstWhere(
        (state) =>
            state is ServersLoaded &&
            state.servers.any((server) => server.id == 2),
      );
      bus.dispatch(
        WsEvent(
          table: 'Servers',
          action: ActionType.create,
          data: {
            'server': {'id': 2, 'name': 'Created during load'},
          },
          isSelf: false,
        ),
      );
      await websocketUpdate;

      final merged = bloc.stream.firstWhere(
        (state) => state is ServersLoaded && state.servers.length == 2,
      );
      repository.release.complete();
      await merged;
      expect(repository.getByIdCached(1)?.name, 'Stale response');
      expect(repository.getByIdCached(2)?.name, 'Created during load');

      await bloc.close();
      bus.dispose();
    },
  );

  testWidgets('ServersSidebar displays loaded server and unread count', (
    tester,
  ) async {
    final repository = _FakeServerRepository();
    final bus = WsEventBus();
    final bloc = ServersBloc(repository, bus)..add(const GetServers());

    await tester.pumpWidget(
      BlocProvider<ServersBloc>.value(
        value: bloc,
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: ServersSidebar(personalUnreadCount: 0),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ServerItem), findsNWidgets(4));
    expect(find.byKey(const ValueKey('discover_servers_item')), findsOneWidget);
    expect(find.text('O'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await bloc.close();
      bus.dispose();
    });
  });
}

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/server_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/category_channel.dart';
import 'package:disalive/domain/models/call_data.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/category_channel_repository.dart';
import 'package:disalive/domain/repositories/calls_repository.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/requests_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/dm_sidebar/dm_sidebar.dart';
import 'package:disalive/presentation/features/home/widgets/chats_view.dart';
import 'package:disalive/presentation/features/requests/bloc/requests_bloc.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/server/server_content_sidebar.dart';
import 'package:disalive/presentation/features/server/server_discovery_sidebar.dart';
import 'package:disalive/presentation/features/server/server_form_screen.dart';
import 'package:disalive/presentation/features/server/widgets/server_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Calls implements CallsRepository {
  @override
  Future<Either<Failure, CallParticipants>> getParticipants({
    required EntityKey entityKey,
    int? chatId,
  }) async => const Right(CallParticipants({}));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Servers implements ServerRepository {
  List<Server> cached = [];
  int? _selectedServerId;
  @override
  int? get selectedServerId => _selectedServerId;
  @override
  Server? get selectedServer =>
      cached.where((server) => server.id == _selectedServerId).firstOrNull;
  @override
  void selectServer(int? serverId) => _selectedServerId = serverId;
  @override
  Future<Either<Failure, List<Server>>> get({
    bool isPublic = false,
    ServerType? category,
    String? query,
  }) async {
    if (isPublic) {
      return const Right([Server(id: 8, name: 'Public', memberCount: 12)]);
    }
    cached = [const Server(id: 2, name: 'Team')];
    return Right(cached);
  }

  @override
  List<Server> getCached() => cached;
  @override
  void updateCache(List<Server> servers) => cached = List.from(servers);
  @override
  void clear() {
    cached = [];
    _selectedServerId = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Channels implements ChannelServerRepository {
  final Map<int, List<ChannelServer>> cache = {};
  @override
  Future<Either<Failure, List<ChannelServer>>> get(int serverId) async {
    final list = [
      ChannelServer(id: 10, serverId: serverId, chatName: 'General'),
    ];
    updateCache(serverId, list);
    return Right(list);
  }

  @override
  List<ChannelServer> getCached(int serverId) => cache[serverId] ?? [];
  @override
  void updateCache(int serverId, List<ChannelServer> channels) =>
      cache[serverId] = List.from(channels);
  @override
  void clear([int? serverId]) {
    if (serverId == null) {
      cache.clear();
    } else {
      cache.remove(serverId);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Categories implements CategoryChannelRepository {
  final Map<int, List<CategoryChannel>> cache = {};
  @override
  Future<Either<Failure, List<CategoryChannel>>> get(int serverId) async {
    updateCache(serverId, []);
    return const Right([]);
  }

  @override
  List<CategoryChannel> getCached(int serverId) => cache[serverId] ?? [];
  @override
  void updateCache(int serverId, List<CategoryChannel> categories) =>
      cache[serverId] = List.from(categories);
  @override
  void clear([int? serverId]) {
    if (serverId == null) {
      cache.clear();
    } else {
      cache.remove(serverId);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Chats implements ChatRepository {
  @override
  void clear() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Requests implements RequestsRepository {
  @override
  void clear() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'discovery layout toggle works beside the server rail on a 320px screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await sl.reset();
      final bus = WsEventBus();
      final serverRepository = _Servers();
      final serversBloc = ServersBloc(serverRepository, bus)
        ..add(const GetServers());
      final chatBloc = ChatBloc(_Chats(), bus);
      final requestsBloc = RequestsBloc(_Requests(), bus);
      final gridView = ValueNotifier(false);
      addTearDown(gridView.dispose);
      sl.registerSingleton<WsEventBus>(bus);
      sl.registerSingleton<CallsRepository>(_Calls());
      sl.registerSingleton<ServerRepository>(serverRepository);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<ServersBloc>.value(value: serversBloc),
            BlocProvider<ChatBloc>.value(value: chatBloc),
            BlocProvider<RequestsBloc>.value(value: requestsBloc),
          ],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: ValueListenableBuilder<bool>(
                valueListenable: gridView,
                builder: (context, grid, child) => ChatsView(
                  isReconnect: false,
                  personalUnreadCount: 0,
                  discoveryGridView: grid,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const ValueKey('discover_servers_item')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final categories = find.descendant(
        of: find.byType(ServerDiscoverySidebar),
        matching: find.byType(ListView),
      );
      expect(tester.widget<ListView>(categories).clipBehavior, Clip.none);
      int columns() => [1, 2, 3, 4].firstWhere(
        (count) => find
            .byKey(ValueKey('public_servers_columns_$count'))
            .evaluate()
            .isNotEmpty,
      );
      expect(columns(), 1);

      gridView.value = true;
      await tester.pump();
      expect(columns(), 2);
      expect(tester.takeException(), isNull);
      gridView.value = false;
      await tester.pump();
      expect(columns(), 1);

      await tester.drag(categories, const Offset(-85, 0));
      await tester.pump();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('public_category_all'))).dx,
        lessThan(72),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await serversBloc.close();
        await chatBloc.close();
        await requestsBloc.close();
        bus.dispose();
        await sl.reset();
      });
    },
  );

  testWidgets(
    'selecting a server replaces DM sidebar and DM button restores it',
    (tester) async {
      await sl.reset();
      final bus = WsEventBus();
      final serverRepository = _Servers();
      final serversBloc = ServersBloc(serverRepository, bus)
        ..add(const GetServers());
      final chatBloc = ChatBloc(_Chats(), bus);
      final requestsBloc = RequestsBloc(_Requests(), bus);
      sl.registerSingleton<WsEventBus>(bus);
      sl.registerSingleton<CallsRepository>(_Calls());
      sl.registerSingleton<ServerRepository>(serverRepository);
      sl.registerSingleton<ChannelServerRepository>(_Channels());
      sl.registerSingleton<CategoryChannelRepository>(_Categories());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<ServersBloc>.value(value: serversBloc),
            BlocProvider<ChatBloc>.value(value: chatBloc),
            BlocProvider<RequestsBloc>.value(value: requestsBloc),
          ],
          child: const CupertinoApp(
            home: CupertinoPageScaffold(
              child: ChatsView(isReconnect: false, personalUnreadCount: 0),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(DirectMessagesSidebar), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('discover_servers_item')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.text('Найдите сообщества себе по душе в Disalive'),
        findsOneWidget,
      );
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Присоединиться'), findsOneWidget);
      expect(find.byType(DirectMessagesSidebar), findsNothing);
      await tester.tap(find.byKey(const ValueKey('dm_server_item')));
      await tester.pump();
      expect(find.byType(DirectMessagesSidebar), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(ServerFormScreen), findsOneWidget);
      await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byType(ServerItem).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(ServerContentSidebar), findsOneWidget);
      expect(sl<ServerRepository>().selectedServer?.id, 2);
      expect(find.text('General'), findsOneWidget);
      expect(find.byType(DirectMessagesSidebar), findsNothing);

      await tester.tap(find.byKey(const ValueKey('dm_server_item')));
      await tester.pump();
      expect(find.byType(DirectMessagesSidebar), findsOneWidget);
      expect(find.byType(ServerContentSidebar), findsNothing);
      expect(sl<ServerRepository>().selectedServer, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await serversBloc.close();
        await chatBloc.close();
        await requestsBloc.close();
        bus.dispose();
        await sl.reset();
      });
    },
  );
}

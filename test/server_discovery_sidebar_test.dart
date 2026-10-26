import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/enums/server_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/presentation/features/server/server_discovery_sidebar.dart';
import 'package:disalive/presentation/widgets/error_state_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

class _Servers implements ServerRepository {
  List<Server>? records;
  bool? publicRequested;
  ServerType? selectedCategory;
  String? selectedQuery;
  bool fail = false;
  int getCalls = 0;

  @override
  Future<Either<Failure, List<Server>>> get({
    bool isPublic = false,
    ServerType? category,
    String? query,
  }) async {
    getCalls++;
    publicRequested = isPublic;
    selectedCategory = category;
    selectedQuery = query;
    if (fail) return const Left(ServerFailure('Не удалось загрузить серверы'));
    return Right(records ?? const [
      Server(
        id: 1,
        name: 'Open',
        memberId: 7,
        memberCount: 12,
        onlineMemberCount: 3,
      ),
      Server(
        id: 2,
        name: 'Long name of server',
        memberCount: 8,
        onlineMemberCount: 2,
      ),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Members implements MembersRepository {
  int? joinedId;
  EntityType? joinedType;

  @override
  Future<Either<Failure, Server>> create(
    int entityId,
    EntityType entityType,
  ) async {
    joinedId = entityId;
    joinedType = entityType;
    return Right(Server(id: entityId, name: 'New', memberId: 11));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('banner server card lays out in list and compact grid', (tester) async {
    await sl.reset();
    final servers = _Servers()..records = const [
      Server(id: 1, name: 'Команда', pathBanner: '/images/banner.gif', memberId: 7,
        memberCount: 10, onlineMemberCount: 2),
    ];
    sl.registerSingleton<ServerRepository>(servers);
    await tester.pumpWidget(CupertinoApp(home: CupertinoPageScaffold(
      child: ServerDiscoverySidebar(gridView: false, onOpenServer: (_) {}, onJoinedServer: (_) {}),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('public_server_1')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(CupertinoApp(home: CupertinoPageScaffold(
      child: ServerDiscoverySidebar(gridView: true, onOpenServer: (_) {}, onJoinedServer: (_) {}),
    )));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('public_server_1')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await sl.reset();
  });
  testWidgets('discovery shows ErrorStateView and retries loading', (
    tester,
  ) async {
    await sl.reset();
    final servers = _Servers()..fail = true;
    sl.registerSingleton<ServerRepository>(servers);

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: ServerDiscoverySidebar(
            gridView: false,
            onOpenServer: (_) {},
            onJoinedServer: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(ErrorStateView), findsOneWidget);
    expect(find.text('Не удалось загрузить серверы'), findsOneWidget);

    servers.fail = false;
    await tester.tap(find.text('Повторить'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(ErrorStateView), findsNothing);
    expect(find.text('Open'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await sl.reset();
  });

  testWidgets('discovery filters public servers and opens or joins them', (
    tester,
  ) async {
    await sl.reset();
    final servers = _Servers();
    final members = _Members();
    sl.registerSingleton<ServerRepository>(servers);
    sl.registerSingleton<MembersRepository>(members);
    Server? opened;
    Server? joined;

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: ServerDiscoverySidebar(
            gridView: false,
            onOpenServer: (server) => opened = server,
            onJoinedServer: (server) => joined = server,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(servers.publicRequested, isTrue);
    expect(
      find.text('Найдите сообщества себе по душе в Disalive'),
      findsOneWidget,
    );
    expect(find.textContaining('Любите игры, музыку'), findsNothing);
    expect(find.text('Открыть сервер'), findsOneWidget);
    expect(find.text('Присоединиться'), findsOneWidget);
    expect(find.text('3 в сети'), findsOneWidget);
    expect(find.text('12 участников'), findsOneWidget);
    expect(find.byKey(const ValueKey('refresh_public_servers')), findsNothing);
    expect(find.byKey(const ValueKey('public_category_NONE')), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(servers.getCalls, greaterThan(1));

    await tester.tap(find.byKey(const ValueKey('public_category_GAMES')));
    await tester.pump();
    await tester.pump();
    expect(servers.selectedCategory, ServerType.games);

    await tester.enterText(
      find.byKey(const ValueKey('public_server_search')),
      'Команда',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(servers.selectedQuery, 'Команда');

    await tester.tap(find.byKey(const ValueKey('public_server_action_1')));
    expect(opened?.id, 1);
    await tester.ensureVisible(
      find.byKey(const ValueKey('public_server_action_2')),
    );
    await tester.tap(find.byKey(const ValueKey('public_server_action_2')));
    await tester.pump();
    expect(members.joinedId, 2);
    expect(members.joinedType, EntityType.server);
    expect(joined?.memberId, 11);

    await tester.pumpWidget(const SizedBox.shrink());
    await sl.reset();
  });

  testWidgets('layout button state changes server cards to grid and back', (
    tester,
  ) async {
    await sl.reset();
    sl.registerSingleton<ServerRepository>(_Servers());
    Future<void> showLayout(bool gridView) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 288,
                child: ServerDiscoverySidebar(
                  gridView: gridView,
                  onOpenServer: (_) {},
                  onJoinedServer: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    await showLayout(false);
    int columns() => [1, 2, 3, 4].firstWhere(
      (count) => find
          .byKey(ValueKey('public_servers_columns_$count'))
          .evaluate()
          .isNotEmpty,
    );
    expect(columns(), 1);

    await showLayout(true);
    expect(columns(), 2);
    expect(tester.widget<Text>(find.text('Long name of server')).maxLines, 1);
    expect(
      find.byKey(const ValueKey('public_servers_columns_2')),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3 в сети'), findsNothing);
    expect(find.text('12 участников'), findsNothing);
    expect(find.text('Присоединиться'), findsNothing);
    expect(find.text('Открыть сервер'), findsNothing);
    expect(find.byIcon(CupertinoIcons.person_add_solid), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.arrow_right), findsOneWidget);
    final nameBottom = tester.getRect(find.text('Open')).bottom;
    final actionTop = tester
        .getRect(find.byKey(const ValueKey('public_server_action_1')))
        .top;
    expect(actionTop - nameBottom, lessThan(20));
    final card = tester.getRect(find.byKey(const ValueKey('public_server_1')));
    final action = tester.getRect(
      find.byKey(const ValueKey('public_server_action_1')),
    );
    expect(card.height, lessThan(150));
    expect(card.bottom - action.bottom, closeTo(8, 2));
    expect(tester.takeException(), isNull);
    await showLayout(false);
    expect(columns(), 1);
    expect(tester.widget<Text>(find.text('Long name of server')).maxLines, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await sl.reset();
  });
}

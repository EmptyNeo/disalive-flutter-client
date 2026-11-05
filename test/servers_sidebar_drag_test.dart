import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/enums/server_type.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/server_list_layout.dart';
import 'package:disalive/domain/repositories/server_list_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/server/bloc/server_list_cubit.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/server/servers_sidebar.dart';
import 'package:disalive/presentation/widgets/app_text_input_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Servers implements ServerRepository {
  List<Server> servers = const [
    Server(id: 1, name: 'Alpha'),
    Server(id: 2, name: 'Beta'),
  ];

  @override
  Future<Either<Failure, List<Server>>> get({
    bool isPublic = false,
    String? query,
    ServerType? category,
  }) async => Right(servers);

  @override
  List<Server> getCached() => servers;

  @override
  void updateCache(List<Server> value) => servers = List.of(value);

  @override
  void selectServer(int? id) {}

  @override
  int? get selectedServerId => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Layout implements ServerListRepository {
  ServerListLayout stored = const ServerListLayout([
    ServerListItem.server(1),
    ServerListItem.server(2),
  ]);

  @override
  Future<Either<Failure, ServerListLayout>> getLayout() async => Right(stored);

  @override
  Future<Either<Failure, ServerListLayout>> saveLayout(
    ServerListLayout layout,
  ) async {
    stored = ServerListLayout([
      for (final item in layout.items)
        item.isFolder && item.folderId == null
            ? ServerListItem.folder(
                folderId: 10,
                name: item.name,
                servers: item.servers,
              )
            : item,
    ]);
    return Right(stored);
  }
}

void main() {
  tearDown(() async => sl.reset());

  testWidgets('server drag creates a folder and long press opens its actions', (
    tester,
  ) async {
    await sl.reset();
    final layout = _Layout();
    final cubit = ServerListCubit(layout);
    sl.registerSingleton<ServerListRepository>(layout);
    sl.registerSingleton<ServerListCubit>(cubit);
    final bloc = ServersBloc(_Servers(), WsEventBus())..add(const GetServers());
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: BlocProvider.value(
            value: bloc,
            child: const ServersSidebar(personalUnreadCount: 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(cubit.state.loaded, isTrue);
    final alpha = find.byKey(const ValueKey('server_1'));
    final beta = find.byKey(const ValueKey('server_2'));
    final gesture = await tester.startGesture(tester.getCenter(alpha));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(beta));
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      layout.stored.items.length,
      1,
      reason: '${layout.stored.items.map((item) => item.toMap()).toList()}',
    );
    expect(layout.stored.items.single.servers, [2, 1]);
    final folder = find.byKey(const ValueKey('folder_10'));
    expect(folder, findsOneWidget);
    final header = find.byKey(const ValueKey('folder_header_10'));
    expect(
      find.descendant(of: header, matching: find.text('A')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: header,
        matching: find.byIcon(CupertinoIcons.folder_fill),
      ),
      findsNothing,
    );
    await tester.tap(header);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('folder_10')), findsOneWidget);
    expect(
      find.descendant(
        of: header,
        matching: find.byIcon(CupertinoIcons.folder_fill),
      ),
      findsOneWidget,
    );

    final contents = find.byKey(const ValueKey('folder_contents_10'));
    expect(tester.widget<Visibility>(contents).visible, isTrue);
    final folderDrag = await tester.startGesture(tester.getCenter(header));
    await tester.pump(const Duration(milliseconds: 600));
    await folderDrag.moveBy(const Offset(0, -24));
    await tester.pump();
    expect(tester.widget<Visibility>(contents).visible, isFalse);
    await folderDrag.up();
    await tester.pumpAndSettle();
    expect(tester.widget<Visibility>(contents).visible, isTrue);

    await tester.longPress(header);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Переименовать папку'), findsOneWidget);
    await tester.tap(find.text('Переименовать папку'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AppTextInputSheet), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

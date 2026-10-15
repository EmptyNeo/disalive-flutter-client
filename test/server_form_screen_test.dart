import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/server_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/server/server_form_screen.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

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
  String? savedName;
  int? savedId;
  int? savedCanInvite;
  int? savedPrivate;
  ServerType? savedCategory;

  @override
  Future<Either<Failure, Server>> create(
    String name, {
    int canInvite = 1,
    int isPrivate = 0,
    ServerType? category,
    File? avatar,
  }) async {
    _save(null, name, canInvite, isPrivate, category);
    return Right(
      Server(
        id: 9,
        name: name,
        canInvite: canInvite,
        private: isPrivate,
        category: category,
      ),
    );
  }

  @override
  Future<Either<Failure, Server>> update(
    int id,
    String name, {
    int? canInvite,
    int? isPrivate,
    ServerType? category,
    int? fkMainChannel,
    bool isSetNullMainChannel = false,
    File? avatar,
  }) async {
    _save(id, name, canInvite, isPrivate, category);
    return Right(
      Server(
        id: id,
        name: name,
        canInvite: canInvite,
        private: isPrivate,
        category: category,
      ),
    );
  }

  void _save(
    int? id,
    String name,
    int? canInvite,
    int? isPrivate,
    ServerType? category,
  ) {
    savedId = id;
    savedName = name;
    savedCanInvite = canInvite;
    savedPrivate = isPrivate;
    savedCategory = category;
  }

  @override
  Future<Either<Failure, List<Server>>> get() async => Right(cached);
  @override
  List<Server> getCached() => cached;
  @override
  void updateCache(List<Server> servers) => cached = List.of(servers);
  @override
  Server? getByIdCached(int id) =>
      cached.where((server) => server.id == id).firstOrNull;
  @override
  void clear() {
    cached = [];
    _selectedServerId = null;
  }
}

Future<({ServersBloc bloc, WsEventBus bus, _Servers repository})> _pump(
  WidgetTester tester, {
  Server? server,
}) async {
  await sl.reset();
  final repository = _Servers();
  final bus = WsEventBus();
  final bloc = ServersBloc(repository, bus);
  sl.registerSingleton<ServerRepository>(repository);
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoPageScaffold(
            child: Center(
              child: CupertinoButton(
                onPressed: () => ServerFormScreen.open(context, server: server),
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Открыть'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return (bloc: bloc, bus: bus, repository: repository);
}

void main() {
  testWidgets('создание передаёт имя, категорию и настройки в репозиторий', (
    tester,
  ) async {
    final setup = await _pump(tester);
    expect(find.byType(ServerFormScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('server_name_field')),
      'Команда',
    );
    await tester.tap(find.byKey(const ValueKey('server_category_picker')));
    await tester.pumpAndSettle();
    expect(
      find.byIcon(CupertinoIcons.check_mark_circled_solid),
      findsOneWidget,
    );
    await tester.tap(find.text('Игры').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server_can_invite_switch')));
    await tester.tap(find.byKey(const ValueKey('server_private_switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать сервер').last);
    await tester.pumpAndSettle();
    expect(setup.repository.savedName, 'Команда');
    expect(setup.repository.savedCategory, ServerType.games);
    expect(setup.repository.savedCanInvite, 0);
    expect(setup.repository.savedPrivate, 1);
    expect(setup.repository.getByIdCached(9)?.name, 'Команда');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await setup.bloc.close();
      setup.bus.dispose();
      await sl.reset();
    });
  });

  testWidgets(
    'редактирование открывает заполненную форму и сохраняет изменения',
    (tester) async {
      final setup = await _pump(
        tester,
        server: const Server(
          id: 4,
          name: 'Старое',
          pathAvatar: 'uploads/server.png',
          category: ServerType.music,
          canInvite: 0,
          private: 1,
        ),
      );
      final nameField = tester.widget<CupertinoTextField>(
        find.byKey(const ValueKey('server_name_field')),
      );
      expect(nameField.controller!.text, 'Старое');
      expect(
        tester.widget<BuildAvatar>(find.byType(BuildAvatar)).url,
        'https://disalive.ru/uploads/server.png',
      );
      expect(find.byIcon(CupertinoIcons.pencil), findsOneWidget);
      expect(find.text('Музыка'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoSwitch>(
              find.byKey(const ValueKey('server_can_invite_switch')),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<CupertinoSwitch>(
              find.byKey(const ValueKey('server_private_switch')),
            )
            .value,
        isTrue,
      );
      await tester.enterText(
        find.byKey(const ValueKey('server_name_field')),
        'Новое',
      );
      await tester.tap(find.text('Сохранить').last);
      await tester.pumpAndSettle();
      expect(setup.repository.savedId, 4);
      expect(setup.repository.savedName, 'Новое');
      expect(setup.repository.savedCategory, ServerType.music);
      expect(setup.repository.savedCanInvite, 0);
      expect(setup.repository.savedPrivate, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await setup.bloc.close();
        setup.bus.dispose();
        await sl.reset();
      });
    },
  );
}

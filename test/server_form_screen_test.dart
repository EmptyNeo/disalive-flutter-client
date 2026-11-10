import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/server_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/server_tag.dart';
import 'package:disalive/domain/repositories/role_member_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/server/server_form_screen.dart';
import 'package:disalive/presentation/features/server/widgets/server_tags_field.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Roles implements RoleMemberRepository {
  @override
  Future<Either<Failure, List<RoleMember>>> get(
    int entityId,
    EntityType entityType,
  ) async => const Right([
    RoleMember(id: 3, name: 'Участник', emoji: '⭐'),
    RoleMember(id: 7, name: 'Модератор'),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Servers implements ServerRepository {
  List<ServerTag> suggestions = const [];
  @override
  Future<Either<Failure, List<ServerTag>>> searchTags(String query) async =>
      Right(suggestions);
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
  String? savedDescription;
  int? savedCanInvite;
  int? savedPrivate;
  ServerType? savedCategory;
  int? savedMainRoleId;
  bool savedClearMainRole = false;
  bool savedDeleteBanner = false;
  List<String> savedTags = [];

  @override
  Future<Either<Failure, Server>> create(
    String name, {
    String description = '',
    int canInvite = 1,
    int isPrivate = 0,
    bool isAdult = false,
    ServerType? category,
    File? avatar,
    File? banner,
    List<String> tags = const [],
  }) async {
    savedTags = tags;
    _save(null, name, description, canInvite, isPrivate, category);
    return Right(
      Server(
        id: 9,
        name: name,
        description: description,
        canInvite: canInvite,
        private: isPrivate,
        isAdult: isAdult,
        category: category,
      ),
    );
  }

  @override
  Future<Either<Failure, Server>> update(
    int id,
    String name, {
    String? description,
    int? canInvite,
    int? isPrivate,
    bool? isAdult,
    ServerType? category,
    int? fkMainChannel,
    bool isSetNullMainChannel = false,
    int? fkMainRole,
    bool isSetNullMainRole = false,
    File? avatar,
    File? banner,
    bool deleteBanner = false,
    List<String>? tags,
  }) async {
    savedTags = tags ?? [];
    _save(id, name, description ?? '', canInvite, isPrivate, category);
    savedMainRoleId = fkMainRole;
    savedClearMainRole = isSetNullMainRole;
    savedDeleteBanner = deleteBanner;
    return Right(
      Server(
        id: id,
        name: name,
        description: description,
        canInvite: canInvite,
        private: isPrivate,
        isAdult: isAdult ?? false,
        category: category,
      ),
    );
  }

  void _save(
    int? id,
    String name,
    String description,
    int? canInvite,
    int? isPrivate,
    ServerType? category,
  ) {
    savedId = id;
    savedName = name;
    savedDescription = description;
    savedCanInvite = canInvite;
    savedPrivate = isPrivate;
    savedCategory = category;
  }

  @override
  Future<Either<Failure, List<Server>>> get({
    bool isPublic = false,
    ServerType? category,
    String? query,
  }) async => Right(cached);
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  sl.registerSingleton<RoleMemberRepository>(_Roles());
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

Future<void> _reveal(
  WidgetTester tester,
  Finder finder, {
  double delta = 150,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find
        .descendant(
          of: find.byType(ServerFormScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('подсказки тегов перекрывают форму, а плюс стоит справа', (
    tester,
  ) async {
    await sl.reset();
    final repository = _Servers()
      ..suggestions = const [ServerTag(name: 'Игры', usageCount: 4)];
    sl.registerSingleton<ServerRepository>(repository);
    List<String> selected = const [];
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ServerTagsField(
                  initialTags: const [],
                  onChanged: (tags) => selected = tags,
                ),
                const SizedBox(height: 12),
                const Text('Следующее поле'),
              ],
            ),
          ),
        ),
      ),
    );
    final nextTop = tester.getTopLeft(find.text('Следующее поле')).dy;
    await tester.enterText(
      find.byKey(const ValueKey('server_tag_input')),
      'Иг',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(tester.getTopLeft(find.text('Следующее поле')).dy, nextTop);
    final field = tester.getRect(
      find.byKey(const ValueKey('server_tags_field')),
    );
    final add = tester.getRect(find.byKey(const ValueKey('server_tag_add')));
    expect(field.right - add.right, closeTo(10, 1));
    expect(
      tester.getTopLeft(find.text('4 исп.')).dy,
      greaterThan(field.bottom),
    );
    await tester.tap(find.text('Игры'));
    await tester.pump();
    expect(selected, ['Игры']);
    expect(find.text('4 исп.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await sl.reset();
  });

  test(
    'баннер читается из ответа и nullable поля передаются при обновлении состояния',
    () {
      final server = Server.fromMap(const {
        'id': 4,
        'name': 'Команда',
        'description': 'Описание сообщества',
        'pathBanner': '/images/banner.gif',
        'pathBannerKey': 'server/banner.gif',
      });
      expect(server.pathBanner, '/images/banner.gif');
      expect(server.pathBannerKey, 'server/banner.gif');
      expect(server.description, 'Описание сообщества');
      expect(server.toMap()['pathBanner'], '/images/banner.gif');
      expect(server.toMap()['description'], 'Описание сообщества');
      expect(
        Server.fromMap({...server.toMap(), 'pathBanner': null}).pathBanner,
        isNull,
      );
      expect(
        Server.fromMap({...server.toMap(), 'description': null}).description,
        isNull,
      );
    },
  );

  testWidgets('удаление баннера передаёт deleteBanner в репозиторий', (
    tester,
  ) async {
    final setup = await _pump(
      tester,
      server: const Server(
        id: 4,
        name: 'Команда',
        pathBanner: '/images/banner.gif',
      ),
    );
    expect(find.byKey(const ValueKey('server_banner_picker')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('server_banner_remove')));
    await tester.pump();
    await tester.tap(find.text('Сохранить').last);
    await tester.pumpAndSettle();
    expect(setup.repository.savedDeleteBanner, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await setup.bloc.close();
      setup.bus.dispose();
      await sl.reset();
    });
  });
  testWidgets('создание передаёт имя, категорию и настройки в репозиторий', (
    tester,
  ) async {
    final setup = await _pump(tester);
    expect(find.byType(ServerFormScreen), findsOneWidget);
    await _reveal(tester, find.byKey(const ValueKey('server_name_field')));
    await tester.enterText(
      find.byKey(const ValueKey('server_name_field')),
      'Команда',
    );
    await _reveal(
      tester,
      find.byKey(const ValueKey('server_description_field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('server_description_field')),
      'Описание команды',
    );
    await _reveal(tester, find.byKey(const ValueKey('server_tag_input')));
    await tester.enterText(
      find.byKey(const ValueKey('server_tag_input')),
      '  Игры  ',
    );
    await tester.pump();
    await tester.drag(find.byType(ListView).last, const Offset(0, 100));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('server_tag_add')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('server_category_picker')));
    await tester.pumpAndSettle();
    expect(
      find.byIcon(CupertinoIcons.check_mark_circled_solid),
      findsOneWidget,
    );
    await tester.tap(find.text('Игры').last);
    await tester.pumpAndSettle();
    await _reveal(
      tester,
      find.byKey(const ValueKey('server_can_invite_switch')),
    );
    await tester.tap(find.byKey(const ValueKey('server_can_invite_switch')));
    await _reveal(tester, find.byKey(const ValueKey('server_private_switch')));
    await tester.tap(find.byKey(const ValueKey('server_private_switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать сервер').last);
    await tester.pumpAndSettle();
    expect(setup.repository.savedName, 'Команда');
    expect(setup.repository.savedDescription, 'Описание команды');
    expect(setup.repository.savedTags, ['Игры']);
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
          description: 'Старое описание',
          pathAvatar: 'uploads/server.png',
          category: ServerType.music,
          canInvite: 0,
          private: 1,
        ),
      );
      expect(
        tester.widget<BuildAvatar>(find.byType(BuildAvatar)).url,
        'https://disalive.ru/uploads/server.png',
      );
      expect(find.byIcon(CupertinoIcons.pencil), findsOneWidget);
      await _reveal(tester, find.byKey(const ValueKey('server_name_field')));
      final nameField = tester.widget<CupertinoTextField>(
        find.byKey(const ValueKey('server_name_field')),
      );
      expect(nameField.controller!.text, 'Старое');
      await _reveal(
        tester,
        find.byKey(const ValueKey('server_description_field')),
      );
      final descriptionField = tester.widget<CupertinoTextField>(
        find.byKey(const ValueKey('server_description_field')),
      );
      expect(descriptionField.controller!.text, 'Старое описание');
      expect(find.text('Музыка'), findsOneWidget);
      await _reveal(
        tester,
        find.byKey(const ValueKey('server_can_invite_switch')),
      );
      expect(
        tester
            .widget<CupertinoSwitch>(
              find.byKey(const ValueKey('server_can_invite_switch')),
            )
            .value,
        isFalse,
      );
      await _reveal(
        tester,
        find.byKey(const ValueKey('server_private_switch')),
      );
      expect(
        tester
            .widget<CupertinoSwitch>(
              find.byKey(const ValueKey('server_private_switch')),
            )
            .value,
        isTrue,
      );
      await _reveal(
        tester,
        find.byKey(const ValueKey('server_name_field')),
        delta: -150,
      );
      await tester.enterText(
        find.byKey(const ValueKey('server_name_field')),
        'Новое',
      );
      await _reveal(
        tester,
        find.byKey(const ValueKey('server_description_field')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('server_description_field')),
        'Новое описание',
      );
      await tester.tap(find.text('Сохранить').last);
      await tester.pumpAndSettle();
      expect(setup.repository.savedId, 4);
      expect(setup.repository.savedName, 'Новое');
      expect(setup.repository.savedDescription, 'Новое описание');
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

  testWidgets('основную роль можно выбрать и сбросить при редактировании', (
    tester,
  ) async {
    final setup = await _pump(
      tester,
      server: const Server(
        id: 4,
        name: 'Сервер',
        fkMainRole: 7,
        mainRole: RoleMember(id: 7, name: 'Модератор'),
      ),
    );
    await _reveal(
      tester,
      find.byKey(const ValueKey('server_main_role_picker')),
    );
    expect(find.text('Модератор'), findsOneWidget);
    final picker = find.byKey(const ValueKey('server_main_role_picker'));
    final chevron = find.descendant(
      of: picker,
      matching: find.byIcon(CupertinoIcons.chevron_down),
    );
    expect(
      tester.getTopRight(chevron).dx,
      closeTo(tester.getTopRight(picker).dx - 14, 1),
    );
    await tester.tap(find.byKey(const ValueKey('server_main_role_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('main_role_3')));
    await tester.pumpAndSettle();
    expect(find.text('Участник'), findsOneWidget);
    await tester.tap(find.text('Сохранить').last);
    await tester.pumpAndSettle();
    expect(setup.repository.savedMainRoleId, 3);
    expect(setup.repository.savedClearMainRole, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await setup.bloc.close();
      setup.bus.dispose();
      await sl.reset();
    });

    final clearSetup = await _pump(
      tester,
      server: const Server(
        id: 4,
        name: 'Сервер',
        fkMainRole: 7,
        mainRole: RoleMember(id: 7, name: 'Модератор'),
      ),
    );
    await _reveal(
      tester,
      find.byKey(const ValueKey('server_main_role_picker')),
    );
    await tester.tap(find.byKey(const ValueKey('server_main_role_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('main_role_none')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить').last);
    await tester.pumpAndSettle();
    expect(clearSetup.repository.savedMainRoleId, isNull);
    expect(clearSetup.repository.savedClearMainRole, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await clearSetup.bloc.close();
      clearSetup.bus.dispose();
      await sl.reset();
    });
  });
}

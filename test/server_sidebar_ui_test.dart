import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/enums/server_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/category_channel.dart';
import 'package:disalive/domain/models/call_data.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/category_channel_repository.dart';
import 'package:disalive/domain/repositories/calls_repository.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/role_member_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/emojis_handler.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/category_channel/widgets/category_channel_item.dart';
import 'package:disalive/presentation/features/channel_server/widgets/channel_server_item.dart';
import 'package:disalive/presentation/features/chat/widgets/symbols/chat_extra_panel.dart';
import 'package:disalive/presentation/features/server/server_action_permissions.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/server/server_content_sidebar.dart';
import 'package:disalive/presentation/features/server/widgets/server_banner_image.dart';
import 'package:disalive/presentation/widgets/app_text_input_sheet.dart';
import 'package:disalive/presentation/widgets/emoji_widget.dart';
import 'package:disalive/presentation/widgets/buttons/glass_button.dart';
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

class _Channels implements ChannelServerRepository {
  _Channels(this.source);
  final List<ChannelServer> source;
  final Map<int, List<ChannelServer>> cache = {};
  String? lastCreatedName;
  String? lastCreatedType;
  int? lastCreatedMaxParticipants;
  int? lastCreatedCategoryId;
  bool? lastCreatedPrivate;
  List<int> lastCreatedUserIds = [];
  List<int> lastCreatedRoleIds = [];
  String? lastUpdatedName;
  int? lastUpdatedCategoryId;
  int? lastUpdatedMaxParticipants;

  @override
  Future<Either<Failure, ChannelServer>> create(
    int serverId,
    String name, {
    String type = 'text',
    int? categoryId,
    bool isPrivate = false,
    int? maxParticipants,
    List<int> userIds = const [],
    List<int> roleIds = const [],
  }) async {
    lastCreatedName = name;
    lastCreatedType = type;
    lastCreatedMaxParticipants = maxParticipants;
    lastCreatedCategoryId = categoryId;
    lastCreatedPrivate = isPrivate;
    lastCreatedUserIds = List.of(userIds);
    lastCreatedRoleIds = List.of(roleIds);
    return Right(
      ChannelServer(
        id: 99,
        serverId: serverId,
        chatName: name,
        type: type,
        categoryId: categoryId,
        isPrivate: isPrivate,
        maxParticipants: maxParticipants,
        allowedUsers: userIds,
        allowedRoles: roleIds,
      ),
    );
  }

  @override
  Future<Either<Failure, ChannelServer>> update(
    int id, {
    String? name,
    int? categoryId,
    int? maxParticipants,
  }) async {
    lastUpdatedName = name;
    lastUpdatedCategoryId = categoryId;
    lastUpdatedMaxParticipants = maxParticipants;
    final previous = source.firstWhere((channel) => channel.id == id);
    return Right(
      ChannelServer.fromMap({
        ...previous.toMap(),
        'chatName': name,
        'categoryId': categoryId == 0 ? null : categoryId,
        'maxParticipants': maxParticipants,
      }),
    );
  }

  @override
  Future<Either<Failure, List<ChannelServer>>> get(int serverId) async {
    updateCache(serverId, source);
    return Right(List.from(source));
  }

  @override
  List<ChannelServer> getCached(int serverId) => cache[serverId] ?? [];

  @override
  void updateCache(int serverId, List<ChannelServer> channels) {
    cache[serverId] = List.from(channels);
  }

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
  _Categories(this.source);
  final List<CategoryChannel> source;
  final Map<int, List<CategoryChannel>> cache = {};
  String? createdName;
  String? updatedName;
  int? updatedId;
  int? deletedId;

  @override
  Future<Either<Failure, CategoryChannel>> create(
    int serverId,
    String name,
  ) async {
    createdName = name;
    return Right(CategoryChannel(id: 50, serverId: serverId, name: name));
  }

  @override
  Future<Either<Failure, CategoryChannel>> update(int id, String name) async {
    updatedId = id;
    updatedName = name;
    return Right(CategoryChannel(id: id, serverId: 2, name: name));
  }

  @override
  Future<Either<Failure, bool>> delete(int id) async {
    deletedId = id;
    return const Right(true);
  }

  @override
  Future<Either<Failure, List<CategoryChannel>>> get(int serverId) async {
    updateCache(serverId, source);
    return Right(List.from(source));
  }

  @override
  List<CategoryChannel> getCached(int serverId) => cache[serverId] ?? [];

  @override
  void updateCache(int serverId, List<CategoryChannel> categories) {
    cache[serverId] = List.from(categories);
  }

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

class _Roles implements RoleMemberRepository {
  @override
  Future<Either<Failure, List<RoleMember>>> get(
    int entityId,
    EntityType entityType,
  ) async => const Right([RoleMember(id: 5, name: 'Moderators')]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Members implements MembersRepository {
  @override
  Future<Either<Failure, List<Member>>> get(
    int entityId,
    EntityType entityType,
  ) async =>
      const Right([Member(fkUser: 8, user: UserModel(displayName: 'Alice'))]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ServerRepository implements ServerRepository {
  int? updatedMainChannel;
  bool clearedMainChannel = false;
  List<Server> servers = [const Server(id: 2, name: 'Team', isOwner: true)];

  @override
  Future<Either<Failure, Server>> update(
    int id,
    String name, {
    int? canInvite,
    int? isPrivate,
    ServerType? category,
    int? fkMainChannel,
    bool isSetNullMainChannel = false,
    int? fkMainRole,
    bool isSetNullMainRole = false,
    File? avatar,
    File? banner,
    bool deleteBanner = false,
  }) async {
    updatedMainChannel = fkMainChannel;
    clearedMainChannel = isSetNullMainChannel;
    return Right(
      isSetNullMainChannel
          ? Server.fromMap({...servers.first.toMap(), 'fkMainChannel': null})
          : servers.first.copyWith(fkMainChannel: fkMainChannel),
    );
  }

  @override
  List<Server> getCached() => servers;

  @override
  void updateCache(List<Server> updated) => servers = List.of(updated);

  @override
  int? get selectedServerId => 2;

  @override
  void selectServer(int? serverId) {}

  @override
  void clear() => servers = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpSidebar(
  WidgetTester tester, {
  required Server server,
  List<CategoryChannel> categories = const [],
  List<ChannelServer> channels = const [],
  VoidCallback? onInvite,
  ValueChanged<ChannelServer>? onChannelTap,
}) async {
  await sl.reset();
  sl.registerSingleton<WsEventBus>(WsEventBus());
  sl.registerSingleton<CallsRepository>(_Calls());
  sl.registerSingleton<ChannelServerRepository>(_Channels(channels));
  sl.registerSingleton<CategoryChannelRepository>(_Categories(categories));
  await tester.pumpWidget(
    CupertinoApp(
      home: CupertinoPageScaffold(
        child: SizedBox(
          width: 390,
          child: ServerContentSidebar(
            server: server,
            onInvite: onInvite,
            onChannelTap: onChannelTap,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  tearDown(() async {
    await sl.reset();
  });

  testWidgets('название и кнопки находятся поверх баннера сервера', (
    tester,
  ) async {
    await _pumpSidebar(
      tester,
      server: const Server(
        id: 2,
        name: 'Команда',
        pathBanner: '/images/banner.gif',
        isOwner: true,
      ),
    );
    final bannerRect = tester.getRect(find.byType(ServerBannerImage));
    expect(bannerRect.height, 110);
    for (final key in ['server_header', 'server_settings', 'invite_server']) {
      final itemRect = tester.getRect(find.byKey(ValueKey(key)));
      expect(
        bannerRect.contains(itemRect.topLeft) &&
            bannerRect.contains(itemRect.bottomRight),
        isTrue,
      );
    }
    final inviteBottom = tester
        .getRect(find.byKey(const ValueKey('invite_server')))
        .bottom;
    final settingsBottom = tester
        .getRect(find.byKey(const ValueKey('server_settings')))
        .bottom;
    expect(bannerRect.bottom - inviteBottom, closeTo(4, 1));
    expect(settingsBottom, closeTo(inviteBottom, 1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('server header hides read action without unread messages', (
    tester,
  ) async {
    await _pumpSidebar(
      tester,
      server: const Server(id: 2, name: 'Team', newMessagesCount: 0),
    );
    await tester.tap(find.byKey(const ValueKey('server_header')));
    await tester.pumpAndSettle();
    expect(find.text('Пометить как прочитанное'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('server header shows read action with unread messages', (
    tester,
  ) async {
    await _pumpSidebar(
      tester,
      server: const Server(id: 2, name: 'Team', newMessagesCount: 3),
    );
    await tester.tap(find.byKey(const ValueKey('server_header')));
    await tester.pumpAndSettle();
    expect(find.text('Пометить как прочитанное'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('channel action sets main channel on server', (tester) async {
    await sl.reset();
    final bus = WsEventBus();
    final repository = _ServerRepository();
    final bloc = ServersBloc(repository, bus);
    sl.registerSingleton<WsEventBus>(bus);
    sl.registerSingleton<CallsRepository>(_Calls());
    sl.registerSingleton<ServerRepository>(repository);
    sl.registerSingleton<ChannelServerRepository>(
      _Channels(const [
        ChannelServer(id: 11, serverId: 2, chatId: 90, chatName: 'General'),
      ]),
    );
    sl.registerSingleton<CategoryChannelRepository>(_Categories(const []));

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: SizedBox(
              width: 390,
              child: ServerContentSidebar(
                server: Server(id: 2, name: 'Team', isOwner: true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.longPress(find.text('General'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сделать главным каналом'));
    await tester.pumpAndSettle();
    expect(repository.updatedMainChannel, 11);
    expect(repository.servers.first.fkMainChannel, 11);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await bloc.close();
      bus.dispose();
    });
  });

  testWidgets('main channel action clears the server main channel', (
    tester,
  ) async {
    await sl.reset();
    final bus = WsEventBus();
    final repository = _ServerRepository()
      ..servers = [
        const Server(id: 2, name: 'Team', isOwner: true, fkMainChannel: 11),
      ];
    final bloc = ServersBloc(repository, bus);
    sl.registerSingleton<WsEventBus>(bus);
    sl.registerSingleton<CallsRepository>(_Calls());
    sl.registerSingleton<ServerRepository>(repository);
    sl.registerSingleton<ChannelServerRepository>(
      _Channels(const [
        ChannelServer(id: 11, serverId: 2, chatId: 90, chatName: 'General'),
      ]),
    );
    sl.registerSingleton<CategoryChannelRepository>(_Categories(const []));

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: SizedBox(
              width: 390,
              child: ServerContentSidebar(
                server: Server(
                  id: 2,
                  name: 'Team',
                  isOwner: true,
                  fkMainChannel: 11,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.longPress(find.text('General'));
    await tester.pumpAndSettle();
    expect(find.text('Сделать главным каналом'), findsNothing);
    await tester.tap(find.text('Убрать основной канал'));
    await tester.pumpAndSettle();
    expect(repository.clearedMainChannel, isTrue);
    expect(repository.servers.first.fkMainChannel, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await bloc.close();
      bus.dispose();
    });
  });

  test('server invitation requires the manageInvites role permission', () {
    final none = ServerActionPermissions.fromServer(
      const Server(id: 1, canInvite: 0, permissions: {}),
    );
    expect(none.canInvite, isFalse);
    expect(none.canManageServer, isFalse);
    expect(none.canManageChannels, isFalse);
    expect(none.canManageCategories, isFalse);
    expect(none.canOpenSettings, isFalse);

    final invite = ServerActionPermissions.fromServer(
      const Server(id: 1, canInvite: 1),
    );
    expect(invite.canInvite, isFalse);
    expect(invite.canManageChannels, isFalse);
    expect(invite.canOpenSettings, isFalse);

    final role = ServerActionPermissions.fromServer(
      const Server(
        id: 1,
        canInvite: 0,
        permissions: {
          'manageChannels': true,
          'manageCategories': true,
          'manageInvites': true,
        },
      ),
    );
    expect(role.canInvite, isTrue);
    expect(role.canManageChannels, isTrue);
    expect(role.canManageCategories, isTrue);
    expect(role.canManageInvites, isTrue);
    expect(role.canOpenSettings, isTrue);

    final owner = ServerActionPermissions.fromServer(
      const Server(id: 1, isOwner: true, canInvite: 0),
    );
    expect(owner.canManageServer, isTrue);
    expect(owner.canInvite, isTrue);
    expect(owner.canManageMembers, isTrue);
    expect(owner.canOpenSettings, isTrue);
  });

  testWidgets('channel and category items invoke tap and long press', (
    tester,
  ) async {
    var taps = 0;
    var longPresses = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Column(
            children: [
              ChannelServerItem(
                channel: const ChannelServer(id: 1, chatName: 'General'),
                onTap: () => taps++,
                onLongPress: () => longPresses++,
              ),
              CategoryChannelItem(
                category: const CategoryChannel(id: 2, name: 'News'),
                onTap: () => taps++,
                onLongPress: () => longPresses++,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('General'));
    await tester.tap(find.text('NEWS'));
    expect(taps, 2);
    await tester.longPress(find.text('General'));
    await tester.longPress(find.text('NEWS'));
    expect(longPresses, 2);
  });

  testWidgets('category and channel names render custom emoji tokens', (
    tester,
  ) async {
    await tester.runAsync(() => EmojisHandler.instance.initialize());
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: Column(
            children: [
              CategoryChannelItem(
                category: CategoryChannel(id: 1, name: 'News [people:0]'),
              ),
              ChannelServerItem(
                channel: ChannelServer(id: 2, chatName: 'Talk [people:0]'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(EmojiWidget), findsNWidgets(2));
    expect(find.textContaining('[people:0]'), findsNothing);
  });

  testWidgets('voice channel shows current and maximum participants', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: ChannelServerItem(
            channel: ChannelServer(
              id: 1,
              type: 'voice',
              chatName: 'Разговоры',
              maxParticipants: 10,
            ),
            participantCount: 3,
          ),
        ),
      ),
    );
    expect(find.text('3/10'), findsOneWidget);
  });

  testWidgets('sidebar groups channels and collapses category', (tester) async {
    await _pumpSidebar(
      tester,
      server: const Server(
        id: 2,
        name: 'Team',
        permissions: {'manageChannels': true},
      ),
      categories: const [CategoryChannel(id: 7, serverId: 2, name: 'News')],
      channels: const [
        ChannelServer(id: 10, serverId: 2, chatName: 'General'),
        ChannelServer(id: 11, serverId: 2, categoryId: 7, chatName: 'Updates'),
      ],
    );
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Updates'), findsOneWidget);
    final categoryCenter = tester.getCenter(find.text('NEWS')).dy;
    final firstChannelCenter = tester.getCenter(find.text('Updates')).dy;
    expect(firstChannelCenter - categoryCenter, lessThanOrEqualTo(40));
    await tester.tap(find.text('NEWS'));
    await tester.pump();
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Updates'), findsNothing);
    await tester.tap(find.text('NEWS'));
    await tester.pump();
    expect(find.text('Updates'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('channel does not stay highlighted after opening chat', (
    tester,
  ) async {
    ChannelServer? openedChannel;
    await _pumpSidebar(
      tester,
      server: const Server(id: 2, name: 'Team'),
      channels: const [ChannelServer(id: 10, serverId: 2, chatName: 'General')],
      onChannelTap: (channel) => openedChannel = channel,
    );

    final channelItem = find.byType(ChannelServerItem);
    await tester.tap(find.text('General'));
    await tester.pump();
    expect(openedChannel?.id, 10);
    expect(tester.widget<ChannelServerItem>(channelItem).isSelected, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('empty sidebar and server actions respect permissions', (
    tester,
  ) async {
    await _pumpSidebar(
      tester,
      server: const Server(
        id: 2,
        name: 'Team',
        canInvite: 1,
        permissions: {'manageMembers': true},
      ),
    );
    expect(find.text('Каналов пока нет'), findsOneWidget);
    expect(find.byKey(const ValueKey('empty_create_channel')), findsNothing);
    final settingsButton = find.byKey(const ValueKey('server_settings'));
    final inviteButton = find.byKey(const ValueKey('invite_server'));
    expect(tester.widget<GlassButton>(settingsButton).child, isA<Icon>());
    expect(inviteButton, findsNothing);
    expect(find.text('Настройки'), findsNothing);
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();
    expect(find.text('Управлять участниками'), findsOneWidget);
    expect(find.text('Управлять сервером'), findsNothing);
    expect(find.text('Управлять ролями'), findsNothing);
    expect(find.text('Управлять приглашениями'), findsNothing);
    expect(find.text('Пригласить на сервер'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings is hidden without management rights', (tester) async {
    await _pumpSidebar(
      tester,
      server: const Server(id: 2, name: 'Team', canInvite: 1),
    );
    expect(find.byKey(const ValueKey('server_settings')), findsNothing);
    expect(find.byKey(const ValueKey('invite_server')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('server_header')));
    await tester.pumpAndSettle();
    expect(find.text('Пригласить на сервер'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('owner settings contains four management actions', (
    tester,
  ) async {
    await _pumpSidebar(
      tester,
      server: const Server(id: 2, name: 'Team', isOwner: true),
    );
    await tester.tap(find.byKey(const ValueKey('server_settings')));
    await tester.pumpAndSettle();
    expect(find.text('Управлять сервером'), findsOneWidget);
    expect(find.text('Управлять ролями'), findsOneWidget);
    expect(find.text('Управлять участниками'), findsOneWidget);
    expect(find.text('Управлять приглашениями'), findsOneWidget);
    expect(find.text('Покинуть сервер'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('создание и редактирование категории открывают своё окно ввода', (
    tester,
  ) async {
    await tester.runAsync(() => EmojisHandler.instance.initialize());
    await _pumpSidebar(
      tester,
      server: const Server(id: 2, name: 'Team', isOwner: true),
      categories: const [CategoryChannel(id: 7, serverId: 2, name: 'News')],
    );
    final repository = sl<CategoryChannelRepository>() as _Categories;

    await tester.tap(find.byKey(const ValueKey('server_header')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Создать категорию'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать категорию'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AppTextInputSheet), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('app_text_input_sheet_field')),
      'Новая',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('app_text_input_emoji_button')));
    await tester.pumpAndSettle();
    expect(find.byType(ChatExtraPanel), findsOneWidget);
    await tester.tap(find.byType(EmojiWidget).first);
    await tester.pump();
    final createdField = tester.widget<CupertinoTextField>(
      find.byKey(const ValueKey('app_text_input_sheet_field')),
    );
    expect(createdField.controller!.text, contains('[people:0]'));
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('app_text_input_sheet_save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(repository.createdName, 'Новая[people:0]');

    await tester.longPress(find.text('NEWS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Переименовать категорию'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AppTextInputSheet), findsOneWidget);
    final field = tester.widget<CupertinoTextField>(
      find.byKey(const ValueKey('app_text_input_sheet_field')),
    );
    expect(field.controller!.text, 'News');
    await tester.enterText(
      find.byKey(const ValueKey('app_text_input_sheet_field')),
      'Новости',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('app_text_input_sheet_save')));
    await tester.pump();
    expect(repository.updatedId, 7);
    expect(repository.updatedName, 'Новости');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('удаление категории подтверждается через общий modal', (
    tester,
  ) async {
    await _pumpSidebar(
      tester,
      server: const Server(id: 2, name: 'Team', isOwner: true),
      categories: const [CategoryChannel(id: 7, serverId: 2, name: 'News')],
    );
    final repository = sl<CategoryChannelRepository>() as _Categories;
    await tester.longPress(find.text('NEWS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить категорию'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Удалить категорию?'), findsOneWidget);
    expect(find.text('Категория «News» будет удалена.'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pump();
    expect(repository.deletedId, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('category plus opens channel creation with category selected', (
    tester,
  ) async {
    await _pumpSidebar(
      tester,
      server: const Server(
        id: 2,
        name: 'Team',
        permissions: {'manageChannels': true},
      ),
      categories: const [CategoryChannel(id: 7, serverId: 2, name: 'News')],
    );
    await tester.tap(find.byKey(const ValueKey('add_channel_to_category')));
    await tester.pumpAndSettle();
    expect(find.text('Создать канал'), findsOneWidget);
    expect(find.text('News'), findsOneWidget);
    expect(find.byKey(const ValueKey('channel_name_field')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('channel edit shows fixed type and category without privacy', (
    tester,
  ) async {
    await _pumpSidebar(
      tester,
      server: const Server(
        id: 2,
        name: 'Team',
        permissions: {'manageChannels': true},
      ),
      categories: const [CategoryChannel(id: 7, serverId: 2, name: 'News')],
      channels: const [
        ChannelServer(
          id: 11,
          serverId: 2,
          type: 'voice',
          categoryId: 7,
          chatName: 'Talk',
        ),
      ],
    );
    final repository = sl<ChannelServerRepository>() as _Channels;
    await tester.longPress(find.text('Talk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Редактировать канал'));
    await tester.pumpAndSettle();
    expect(find.text('Тип канала нельзя изменить'), findsOneWidget);
    expect(find.text('News'), findsOneWidget);
    expect(find.byKey(const ValueKey('private_channel_switch')), findsNothing);
    final typeButton = tester.widget<CupertinoButton>(
      find.byKey(const ValueKey('channel_type_text')),
    );
    expect(typeButton.onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('channel_category_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Нет категории').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('channel_name_field')),
      'Voice room',
    );
    await tester.enterText(
      find.byKey(const ValueKey('channel_max_participants_field')),
      '12',
    );
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(repository.lastUpdatedName, 'Voice room');
    expect(repository.lastUpdatedCategoryId, 0);
    expect(repository.lastUpdatedMaxParticipants, 12);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('private channel creation passes selected roles and users', (
    tester,
  ) async {
    await tester.runAsync(() => EmojisHandler.instance.initialize());
    await _pumpSidebar(
      tester,
      server: const Server(
        id: 2,
        name: 'Team',
        permissions: {'manageChannels': true},
      ),
      categories: const [CategoryChannel(id: 7, serverId: 2, name: 'News')],
    );
    final repository = sl<ChannelServerRepository>() as _Channels;
    sl.registerSingleton<RoleMemberRepository>(_Roles());
    sl.registerSingleton<MembersRepository>(_Members());
    await tester.tap(find.byKey(const ValueKey('add_channel_to_category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Создать'));
    await tester.pump();
    expect(repository.lastCreatedName, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('channel_name_field')),
      'Private talk',
    );
    await tester.tap(find.byKey(const ValueKey('channel_name_emoji_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EmojiWidget).first);
    await tester.pump();
    final channelNameField = tester.widget<CupertinoTextField>(
      find.byKey(const ValueKey('channel_name_field')),
    );
    expect(channelNameField.controller!.text, 'Private talk[people:0]');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('channel_type_voice')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('private_channel_switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('private_channel_switch')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('channel_max_participants_field')),
      '8',
    );
    await tester.pump();
    expect(find.text('Далее'), findsOneWidget);
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    expect(find.text('Moderators'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    await tester.enterText(find.byType(CupertinoSearchTextField), 'Moder');
    await tester.pump();
    expect(find.text('Alice'), findsNothing);
    await tester.enterText(find.byType(CupertinoSearchTextField), '');
    await tester.pump();
    await tester.tap(find.text('Moderators'));
    await tester.tap(find.text('Alice'));
    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();
    expect(repository.lastCreatedName, 'Private talk[people:0]');
    expect(repository.lastCreatedType, 'voice');
    expect(repository.lastCreatedMaxParticipants, 8);
    expect(repository.lastCreatedCategoryId, 7);
    expect(repository.lastCreatedPrivate, isTrue);
    expect(repository.lastCreatedUserIds, [8]);
    expect(repository.lastCreatedRoleIds, [5]);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/chat/widgets/chat_header.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/members/widgets/members_list.dart';
import 'package:disalive/presentation/features/profile/channel_profile_screen.dart';
import 'package:disalive/presentation/features/profile/determinant_profile_screen.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Members implements MembersRepository {
  _Members([this.members = const []]);

  final List<Member> members;
  int? requestedId;
  EntityType? requestedType;
  EntityKey? removedFrom;
  int? removedUserId;

  @override
  Future<List<Member>> getCached(EntityKey entityKey) async => const [];

  @override
  Future<Either<Failure, List<Member>>> get(
    int entityId,
    EntityType entityType,
  ) async {
    requestedId = entityId;
    requestedType = entityType;
    return Right(members);
  }

  @override
  Future<Either<Failure, bool>> remove(EntityKey entityKey, int userId) async {
    removedFrom = entityKey;
    removedUserId = userId;
    return const Right(true);
  }

  @override
  void clear() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Servers implements ServerRepository {
  _Servers(this.selectedServer);

  @override
  final Server? selectedServer;

  @override
  int? get selectedServerId => selectedServer?.id;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('channel header uses channel icon instead of avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: ChatHeader(
            chat: Chat(id: 8, name: 'Новости', type: ChatType.channel),
            isReconnect: false,
          ),
        ),
      ),
    );

    expect(find.byIcon(CupertinoIcons.number), findsOneWidget);
    expect(find.byType(BuildAvatar), findsNothing);
  });

  testWidgets('channel profile loads server members only', (tester) async {
    await sl.reset();
    final members = _Members();
    final bus = WsEventBus();
    final bloc = MembersBloc(members, bus);
    sl.registerSingleton<ServerRepository>(
      _Servers(const Server(id: 42, name: 'Сообщество', memberCount: 5)),
    );
    const chat = Chat(id: 8, name: 'Новости', type: ChatType.channel);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoPageScaffold(
              child: Center(
                child: CupertinoButton(
                  onPressed: () =>
                      DeterminantProfileScreen.open(context, chat: chat),
                  child: const Text('Открыть профиль'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Открыть профиль'));
    await tester.pumpAndSettle();
    expect(find.byType(ChannelProfileScreen), findsOneWidget);
    expect(members.requestedId, 42);
    expect(members.requestedType, EntityType.server);
    final membersList = tester.widget<MembersList>(find.byType(MembersList));
    expect(membersList.entityId, 42);
    expect(membersList.entityType, EntityType.server);
    expect(find.text('Пока нет участников'), findsOneWidget);
    expect(find.byType(BuildAvatar), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await bloc.close();
      bus.dispose();
      await sl.reset();
    });
  });

  testWidgets('member action targets the server entity', (tester) async {
    await sl.reset();
    final members = _Members(const [
      Member(
        fkUser: 8,
        isSelf: false,
        user: UserModel(id: 8, displayName: 'Алиса'),
      ),
    ]);
    final bus = WsEventBus();
    final bloc = MembersBloc(members, bus);
    sl.registerSingleton<MembersRepository>(members);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const CupertinoApp(
          home: ChannelProfileScreen(
            chat: Chat(id: 8, name: 'Новости', type: ChatType.channel),
            server: Server(id: 42, name: 'Сообщество', isOwner: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Алиса'));
    await tester.pumpAndSettle();
    expect(find.text('Исключить с сервера'), findsOneWidget);
    await tester.tap(find.text('Исключить с сервера'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Подтвердить'));
    await tester.pumpAndSettle();
    expect(
      members.removedFrom,
      const EntityKey(entityId: 42, entityType: EntityType.server),
    );
    expect(members.removedUserId, 8);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await bloc.close();
      bus.dispose();
      await sl.reset();
    });
  });
}

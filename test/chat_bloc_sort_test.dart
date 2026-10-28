import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/permissions.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChatRepository implements ChatRepository {
  final List<Chat> chats = [
    const Chat(
      id: 2,
      name: 'Recent',
      lastMessageTime: '2026-10-13 11:00:00',
      idLastMessage: 20,
      newMessagesCount: 0,
    ),
    const Chat(
      id: 1,
      name: 'Older',
      lastMessageTime: '2026-10-13 10:00:00',
      idLastMessage: 10,
      newMessagesCount: 2,
    ),
  ];

  @override
  List<Chat> getCached() => chats;

  @override
  int getAllUnredCount() =>
      chats.fold(0, (count, chat) => count + chat.unreadCount);

  @override
  void clear() => chats.clear();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CurrentUserRepository implements UserRepository {
  @override
  UserModel? getCurrentUser() => const UserModel(id: 42);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('updated group role refreshes invitation permission', () async {
    final repository = _FakeChatRepository();
    repository.chats[0] = const Chat(
      id: 2,
      name: 'Группа',
      roleId: 5,
      role: RoleMember(id: 5, permissions: {'manageInvites': false}),
      member: Member(fkRole: 5),
    );
    final bus = WsEventBus();
    final bloc = ChatBloc(repository, bus)..setupListeners();
    final updated = bloc.stream.firstWhere(
      (state) =>
          state is ChatLoaded &&
          state.chats.first.role?.hasPermission(
                ChatPermissions.manageInvites,
              ) ==
              true,
    );
    bus.dispatch(
      WsEvent(
        table: 'RoleMembers',
        action: ActionType.update,
        data: {
          'entityId': 2,
          'entityType': 'chat',
          'role': {
            'id': 5,
            'permissions': {'manageInvites': true},
          },
        },
        isSelf: false,
      ),
    );
    await updated;
    expect(
      repository.chats.first.member?.role?.hasPermission(
        ChatPermissions.manageInvites,
      ),
      isTrue,
    );
    await bloc.close();
    bus.dispose();
  });

  test(
    'deletion reduces only unread messages written by someone else',
    () async {
      await sl.reset();
      sl.registerSingleton<UserRepository>(_CurrentUserRepository());
      final repository = _FakeChatRepository();
      repository.chats[0] = const Chat(
        id: 2,
        name: 'Chat',
        idLastMessage: 23,
        newMessagesCount: 2,
        member: Member(lastIdReadMessage: 20),
      );
      final bus = WsEventBus();
      final bloc = ChatBloc(repository, bus)..setupListeners();

      void remove(int messageId, int authorId) => bus.dispatch(
        WsEvent(
          table: 'Message',
          action: ActionType.delete,
          data: {
            'chatId': 2,
            'messageId': messageId,
            'messageUserId': authorId,
          },
          isSelf: true,
        ),
      );

      remove(23, 9);
      await bloc.stream.firstWhere(
        (state) => state is ChatLoaded && state.chats.first.unreadCount == 1,
      );
      expect(repository.getAllUnredCount(), 3);

      remove(20, 9);
      await Future<void>.delayed(Duration.zero);
      expect(repository.chats.first.unreadCount, 1);

      remove(22, 42);
      await Future<void>.delayed(Duration.zero);
      expect(repository.chats.first.unreadCount, 1);

      await bloc.close();
      bus.dispose();
      await sl.reset();
    },
  );

  test('own message reorders chat without increasing unread count', () async {
    final repository = _FakeChatRepository();
    final bus = WsEventBus();
    final bloc = ChatBloc(repository, bus)..setupListeners();

    final initial = bloc.stream.firstWhere((state) => state is ChatLoaded);
    bloc.add(GetChats());
    await initial;

    final ownUpdate = bloc.stream.firstWhere(
      (state) =>
          state is ChatLoaded &&
          state.chats.first.id == 1 &&
          state.chats.first.idLastMessage == 21,
    );
    bus.dispatch(
      WsEvent(
        table: 'Message',
        action: ActionType.create,
        data: {
          'message': {
            'id': 21,
            'chatId': 1,
            'userId': 42,
            'text': 'Своё сообщение',
            'time': '2026-10-13 12:00:00',
          },
          'lastMessageText': 'Фото',
          'lastMessageUserId': 42,
        },
        isSelf: true,
      ),
    );
    final ownState = (await ownUpdate) as ChatLoaded;
    expect(ownState.chats.map((chat) => chat.id).toList(), [1, 2]);
    expect(repository.getCached().first.newMessagesCount, 2);
    expect(ownState.chats.first.lastMessageText, 'Фото');
    expect(ownState.chats.first.lastMessageUserId, 42);
    expect(ownState.unreadCount, 2);

    final foreignUpdate = bloc.stream.firstWhere(
      (state) =>
          state is ChatLoaded &&
          state.chats.first.id == 2 &&
          state.chats.first.idLastMessage == 22,
    );
    bus.dispatch(
      WsEvent(
        table: 'Message',
        action: ActionType.create,
        data: {
          'message': {
            'id': 22,
            'chatId': 2,
            'userId': 9,
            'text': 'Чужое сообщение',
            'time': '2026-10-13 13:00:00',
          },
        },
        isSelf: false,
      ),
    );
    final foreignState = (await foreignUpdate) as ChatLoaded;
    expect(foreignState.chats.map((chat) => chat.id).toList(), [2, 1]);
    expect(repository.getCached().first.newMessagesCount, 1);
    expect(foreignState.chats.first.lastMessageText, 'Чужое сообщение');
    expect(foreignState.chats.first.lastMessageUserId, 9);
    expect(foreignState.unreadCount, 3);

    await bloc.close();
    bus.dispose();
  });

  test('edit and delete apply the server preview, including null', () async {
    final repository = _FakeChatRepository();
    final bus = WsEventBus();
    final bloc = ChatBloc(repository, bus)..setupListeners();

    final initial = bloc.stream.firstWhere((state) => state is ChatLoaded);
    bloc.add(GetChats());
    await initial;

    bus.dispatch(
      WsEvent(
        table: 'Message',
        action: ActionType.update,
        data: {
          'chatId': 2,
          'message': {'id': 19, 'text': 'Изменено не последнее'},
        },
        isSelf: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repository.chats.first.lastMessageText, isNull);

    final edited = bloc.stream.firstWhere(
      (state) =>
          state is ChatLoaded &&
          state.chats.first.lastMessageText == 'Изменённое превью',
    );
    bus.dispatch(
      WsEvent(
        table: 'Message',
        action: ActionType.update,
        data: {
          'chatId': 2,
          'lastMessageText': 'Изменённое превью',
          'lastMessageUserId': 9,
        },
        isSelf: false,
      ),
    );
    final editedChat = ((await edited) as ChatLoaded).chats.first;
    expect(editedChat.lastMessageUserId, 9);
    expect(editedChat.idLastMessage, 20);

    final restored = bloc.stream.firstWhere(
      (state) =>
          state is ChatLoaded &&
          state.chats.first.lastMessageText == 'Предыдущее сообщение',
    );
    bus.dispatch(
      WsEvent(
        table: 'Message',
        action: ActionType.delete,
        data: {
          'chatId': 2,
          'messageId': 20,
          'lastMessageId': 18,
          'lastMessageText': 'Предыдущее сообщение',
          'lastMessageUserId': 7,
        },
        isSelf: false,
      ),
    );
    final restoredChat = ((await restored) as ChatLoaded).chats.first;
    expect(restoredChat.idLastMessage, 18);
    expect(restoredChat.lastMessageUserId, 7);

    final cleared = bloc.stream.firstWhere(
      (state) =>
          state is ChatLoaded && state.chats.first.lastMessageText == null,
    );
    bus.dispatch(
      WsEvent(
        table: 'Message',
        action: ActionType.delete,
        data: {
          'chatId': 2,
          'messageId': 18,
          'lastMessageId': null,
          'lastMessageText': null,
          'lastMessageUserId': null,
        },
        isSelf: false,
      ),
    );
    final clearedChat = ((await cleared) as ChatLoaded).chats.first;
    expect(clearedChat.lastMessageUserId, isNull);
    expect(clearedChat.idLastMessage, isNull);

    await bloc.close();
    bus.dispose();
  });
}

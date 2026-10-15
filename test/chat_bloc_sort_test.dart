import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
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

void main() {
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
          'message': {'id': 21, 'chatId': 1, 'time': '2026-10-13 12:00:00'},
        },
        isSelf: true,
      ),
    );
    final ownState = (await ownUpdate) as ChatLoaded;
    expect(ownState.chats.map((chat) => chat.id).toList(), [1, 2]);
    expect(repository.getCached().first.newMessagesCount, 2);
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
          'message': {'id': 22, 'chatId': 2, 'time': '2026-10-13 13:00:00'},
        },
        isSelf: false,
      ),
    );
    final foreignState = (await foreignUpdate) as ChatLoaded;
    expect(foreignState.chats.map((chat) => chat.id).toList(), [2, 1]);
    expect(repository.getCached().first.newMessagesCount, 1);
    expect(foreignState.unreadCount, 3);

    await bloc.close();
    bus.dispose();
  });
}

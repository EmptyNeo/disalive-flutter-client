import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/enums/entity_action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/history_action.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/responses/message_response.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/history_actions/history_action_item.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat/widgets/messages_list.dart';
import 'package:disalive/presentation/features/chat/widgets/separators/day_separator.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

class _Messages implements MessageRepository {
  MessagesResponse? cached;
  final pages = <MessagesResponse>[
    const MessagesResponse(
      messages: [Message(id: 10, chatId: 1)],
      actions: [
        HistoryAction(
          id: 1,
          entityId: 1,
          entityType: EntityType.chat,
          entityActionType: EntityActionType.called,
          lastIdMessage: 10,
        ),
      ],
    ),
    const MessagesResponse(
      messages: [Message(id: 9, chatId: 1)],
      actions: [
        HistoryAction(
          id: 2,
          entityId: 1,
          entityType: EntityType.chat,
          entityActionType: EntityActionType.joined,
          lastIdMessage: 9,
        ),
      ],
    ),
  ];

  @override
  Future<Either<Failure, MessagesResponse>> get(
    int chatId,
    int entityId,
    EntityType entityType,
    int limit,
    int lastIdMessage,
    int? aroundId,
    int? newerThanId,
    String? searchQuery,
  ) async => Right(pages.removeAt(0));

  @override
  MessagesResponse? getCached(int chatId) => cached;

  @override
  void cacheMessages(int chatId, List<Message> messages) =>
      cached = (cached ?? const MessagesResponse(messages: [], actions: []))
          .copyWith(messages: messages);

  @override
  void cacheActions(int chatId, List<HistoryAction> actions) =>
      cached = (cached ?? const MessagesResponse(messages: [], actions: []))
          .copyWith(actions: actions);

  @override
  void clearAllCache() => cached = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Chats implements ChatRepository {
  @override
  void clear() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reactions implements ReactionsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('history actions survive pagination and websocket updates', () async {
    final repo = _Messages();
    final bus = WsEventBus();
    final bloc = MessageBloc(repo, _Reactions(), _Chats(), bus)
      ..setupListeners();
    bloc.add(
      GetMessages(
        chatId: 1,
        entityId: 1,
        entityType: EntityType.chat,
        lastIdMessage: 0,
        limit: 1,
      ),
    );
    await bloc.stream.firstWhere((s) => s is MessageLoaded);

    bloc.add(
      GetMessages(
        chatId: 1,
        entityId: 1,
        entityType: EntityType.chat,
        lastIdMessage: 10,
        limit: 1,
      ),
    );
    await bloc.stream.firstWhere(
      (s) => s is MessageLoaded && s.actions.length == 2,
    );
    expect(repo.cached?.actions.map((a) => a.id), [2, 1]);

    bus.dispatch(
      WsEvent(
        table: 'HistoryActions',
        action: ActionType.update,
        isSelf: false,
        data: {
          'action': {
            'id': 1,
            'entityId': 1,
            'entityType': 'chat',
            'entityActionType': 'Called',
            'lastIdMessage': 10,
            'endDate': '2026-10-21 10:00:00',
          },
        },
      ),
    );
    await bloc.stream.firstWhere(
      (s) =>
          s is MessageLoaded &&
          s.actions.any((a) => a.id == 1 && a.endDate != null),
    );
    expect((bloc.state as MessageLoaded).actions.length, 2);
    await bloc.close();
    bus.dispose();
  });

  testWidgets('history action shows actor, target and time', (tester) async {
    const action = HistoryAction(
      id: 3,
      entityType: EntityType.chat,
      entityActionType: EntityActionType.added,
      initiatorUser: UserModel(displayName: 'Алиса'),
      interactionUser: UserModel(displayName: 'Боб'),
      startTimeFormatted: '12:45',
    );
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(child: HistoryActionItem(action: action)),
      ),
    );
    expect(find.textContaining('Алиса'), findsOneWidget);
    expect(find.textContaining('Боб'), findsOneWidget);
    expect(find.text('12:45'), findsOneWidget);
  });

  testWidgets('history action on another day has its own separator', (
    tester,
  ) async {
    final repo = _Messages();
    repo.pages
      ..clear()
      ..add(
        const MessagesResponse(
          messages: [Message(id: 10, chatId: 1, time: '2026-01-01 10:00:00')],
          actions: [
            HistoryAction(
              id: 1,
              entityType: EntityType.chat,
              entityActionType: EntityActionType.called,
              lastIdMessage: 10,
              startDate: '2026-01-02 10:00:00',
            ),
          ],
        ),
      );
    final bus = WsEventBus();
    final chats = _Chats();
    final messageBloc = MessageBloc(repo, _Reactions(), chats, bus);
    final chatBloc = ChatBloc(chats, bus);
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: MessagesList(
            messageBloc: messageBloc,
            chatBloc: chatBloc,
            chat: const Chat(id: 1, name: 'Чат', type: ChatType.personal),
            currentUserId: 1,
            initialAroundId: null,
            inputReserve: 0,
            headerReserve: 0,
            onSendMessage: (_) {},
            onEditMessage: (_) {},
            onDeleteMessage: (_) {},
            onAnswerMessage: (_) {},
            onStickerTap: (_) {},
          ),
        ),
      ),
    );
    messageBloc.add(
      GetMessages(
        chatId: 1,
        entityId: 1,
        entityType: EntityType.chat,
        lastIdMessage: 0,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(DaySeparator), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await messageBloc.close();
      await chatBloc.close();
      bus.dispose();
    });
  });
}

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/responses/message_response.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat/widgets/messages_list.dart';
import 'package:disalive/presentation/features/message/widgets/new_messages_separator.dart';
import 'package:disalive/presentation/features/message/widgets/swipes/swipe_to_reply_message.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

class _Messages implements MessageRepository {
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
  ) async => Right(
    MessagesResponse(
      messages: [Message(id: 11, chatId: chatId, userId: 1, text: 'Привет')],
      actions: const [],
    ),
  );

  @override
  MessagesResponse? getCached(int chatId) => null;

  @override
  void cacheMessages(int chatId, List<Message> messages) {}

  @override
  void clearAllCache() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PagingMessages extends _Messages {
  int? requestedNewerThanId;

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
  ) async {
    if (newerThanId != null) {
      requestedNewerThanId = newerThanId;
      return const Right(MessagesResponse(messages: [], actions: []));
    }
    return Right(
      MessagesResponse(
        messages: [Message(id: 10, chatId: chatId, userId: 1, text: 'История')],
        actions: const [],
      ),
    );
  }
}

class _UnreadMessages extends _Messages {
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
  ) async => Right(
    MessagesResponse(
      messages: [
        Message(id: 12, chatId: chatId, userId: 2, text: 'Новое 12'),
        Message(id: 11, chatId: chatId, userId: 2, text: 'Новое 11'),
        Message(id: 10, chatId: chatId, userId: 2, text: 'Прочитано 10'),
      ],
      actions: const [],
    ),
  );
}

class _PagedUnreadMessages extends _Messages {
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
  ) async {
    if (newerThanId != null) {
      return const Right(MessagesResponse(messages: [], actions: []));
    }
    if (lastIdMessage > 0) {
      return Right(
        MessagesResponse(
          messages: [Message(id: 10, chatId: chatId, userId: 2)],
          actions: const [],
        ),
      );
    }
    return Right(
      MessagesResponse(
        messages: [
          Message(id: 12, chatId: chatId, userId: 2),
          Message(id: 11, chatId: chatId, userId: 2),
        ],
        actions: const [],
      ),
    );
  }
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

class _Server implements ServerRepository {
  @override
  int? get selectedServerId => 2;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Members implements MembersRepository {
  int? readId;
  int? entityId;
  EntityType? entityType;
  int? chatId;

  @override
  Future<Either<Failure, bool>> update({
    required int entityId,
    required EntityType entityType,
    int? chatId,
    int? lastIdReadMessage,
    bool toggleMuted = false,
    bool toggleFixed = false,
  }) async {
    this.entityId = entityId;
    this.entityType = entityType;
    this.chatId = chatId;
    readId = lastIdReadMessage;
    return const Right(true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('separator waits for the loaded read boundary', (tester) async {
    await sl.reset();
    sl.registerSingleton<ServerRepository>(_Server());
    sl.registerSingleton<MembersRepository>(_Members());
    final bus = WsEventBus();
    final chats = _Chats();
    final messageBloc = MessageBloc(
      _PagedUnreadMessages(),
      _Reactions(),
      chats,
      bus,
    );
    final chatBloc = ChatBloc(chats, bus);

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: MessagesList(
            messageBloc: messageBloc,
            chatBloc: chatBloc,
            chat: const Chat(
              id: 90,
              name: 'Чат',
              type: ChatType.personal,
              idLastMessage: 12,
              member: Member(lastIdReadMessage: 10),
            ),
            currentUserId: 1,
            inputReserve: 0,
            initialAroundId: 10,
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
        chatId: 90,
        entityId: 90,
        entityType: EntityType.chat,
        lastIdMessage: 0,
        aroundId: 10,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(NewMessagesSeparator), findsNothing);

    messageBloc.add(
      GetMessages(
        chatId: 90,
        entityId: 90,
        entityType: EntityType.chat,
        lastIdMessage: 11,
      ),
    );
    await tester.pump();
    await tester.pump();
    final separatorColumn = tester.widget<Column>(
      find
          .ancestor(
            of: find.byType(NewMessagesSeparator),
            matching: find.byType(Column),
          )
          .first,
    );
    expect((separatorColumn.children.last.key as ValueKey).value, 11);

    await tester.pumpWidget(const CupertinoApp(home: SizedBox.shrink()));
    await tester.runAsync(() async {
      await messageBloc.close();
      await chatBloc.close();
    });
    bus.dispose();
    await sl.reset();
  });

  for (final chatType in [ChatType.personal, ChatType.channel]) {
    testWidgets('$chatType separator moves after a user scroll and a delay', (
      tester,
    ) async {
      await sl.reset();
      sl.registerSingleton<ServerRepository>(_Server());
      sl.registerSingleton<MembersRepository>(_Members());
      final bus = WsEventBus();
      final chats = _Chats();
      final messageBloc = MessageBloc(
        _UnreadMessages(),
        _Reactions(),
        chats,
        bus,
      );
      final chatBloc = ChatBloc(chats, bus);
      final unreadChat = Chat(
        id: 90,
        name: 'Чат',
        type: chatType,
        idLastMessage: 12,
        newMessagesCount: 2,
        member: Member(lastIdReadMessage: 10),
      );

      Widget screen(Chat chat, int? boundary) => CupertinoApp(
        home: CupertinoPageScaffold(
          child: MessagesList(
            messageBloc: messageBloc,
            chatBloc: chatBloc,
            chat: chat,
            currentUserId: 1,
            inputReserve: 0,
            initialAroundId: boundary,
            onSendMessage: (_) {},
            onEditMessage: (_) {},
            onDeleteMessage: (_) {},
            onAnswerMessage: (_) {},
            onStickerTap: (_) {},
          ),
        ),
      );

      await tester.pumpWidget(screen(unreadChat, 10));
      messageBloc.add(
        GetMessages(
          chatId: 90,
          entityId: 90,
          entityType: EntityType.chat,
          lastIdMessage: 0,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Новые сообщения'), findsOneWidget);
      final separatorColumn = tester.widget<Column>(
        find
            .ancestor(
              of: find.byType(NewMessagesSeparator),
              matching: find.byType(Column),
            )
            .first,
      );
      expect(separatorColumn.children.last, isA<SwipeToReplyMessage>());
      expect((separatorColumn.children.last.key as ValueKey).value, 11);

      await tester.pumpWidget(
        screen(
          unreadChat.copyWith(
            newMessagesCount: 1,
            member: const Member(lastIdReadMessage: 11),
          ),
          11,
        ),
      );
      await tester.pump();
      expect(
        (tester
                    .widget<Column>(
                      find
                          .ancestor(
                            of: find.byType(NewMessagesSeparator),
                            matching: find.byType(Column),
                          )
                          .first,
                    )
                    .children
                    .last
                    .key
                as ValueKey)
            .value,
        11,
      );
      await tester.pump(const Duration(seconds: 1));
      expect((separatorColumn.children.last.key as ValueKey).value, 11);
      await tester.pump(const Duration(milliseconds: 1100));
      expect((separatorColumn.children.last.key as ValueKey).value, 11);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pump();
      expect((separatorColumn.children.last.key as ValueKey).value, 11);
      await tester.pump(const Duration(milliseconds: 2100));
      final movedSeparatorColumn = tester.widget<Column>(
        find
            .ancestor(
              of: find.byType(NewMessagesSeparator),
              matching: find.byType(Column),
            )
            .first,
      );
      expect((movedSeparatorColumn.children.last.key as ValueKey).value, 12);

      await tester.pumpWidget(
        screen(
          unreadChat.copyWith(
            newMessagesCount: 0,
            member: const Member(lastIdReadMessage: 12),
          ),
          null,
        ),
      );
      await tester.pump();
      expect(find.text('Новые сообщения'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Новые сообщения'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('Новые сообщения'), findsNothing);

      await tester.pumpWidget(const CupertinoApp(home: SizedBox.shrink()));
      await tester.runAsync(() async {
        await messageBloc.close();
        await chatBloc.close();
      });
      bus.dispose();
      await sl.reset();
    });
  }

  testWidgets('short channel history loads newer messages without last ID', (
    tester,
  ) async {
    await sl.reset();
    sl.registerSingleton<ServerRepository>(_Server());
    sl.registerSingleton<MembersRepository>(_Members());
    final bus = WsEventBus();
    final chats = _Chats();
    final messages = _PagingMessages();
    final messageBloc = MessageBloc(messages, _Reactions(), chats, bus);
    final chatBloc = ChatBloc(chats, bus);

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: MessagesList(
            messageBloc: messageBloc,
            chatBloc: chatBloc,
            chat: const Chat(
              id: 90,
              name: 'Канал',
              type: ChatType.channel,
              member: Member(lastIdReadMessage: 10),
            ),
            currentUserId: 1,
            inputReserve: 0,
            initialAroundId: null,
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
        chatId: 90,
        entityId: 2,
        entityType: EntityType.server,
        lastIdMessage: 0,
        aroundId: 10,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(messages.requestedNewerThanId, 10);

    await tester.pumpWidget(const CupertinoApp(home: SizedBox.shrink()));
    await tester.runAsync(() async {
      await messageBloc.close();
      await chatBloc.close();
    });
    bus.dispose();
    await sl.reset();
  });

  testWidgets(
    'opening a channel marks its visible message read without scrolling',
    (tester) async {
      await sl.reset();
      sl.registerSingleton<ServerRepository>(_Server());
      final members = _Members();
      sl.registerSingleton<MembersRepository>(members);
      final bus = WsEventBus();
      final chats = _Chats();
      final messageBloc = MessageBloc(_Messages(), _Reactions(), chats, bus);
      final chatBloc = ChatBloc(chats, bus);
      final chat = Chat(
        id: 90,
        name: 'Канал',
        type: ChatType.channel,
        idLastMessage: 11,
        newMessagesCount: 1,
        member: const Member(lastIdReadMessage: 10),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: MessagesList(
              messageBloc: messageBloc,
              chatBloc: chatBloc,
              chat: chat,
              currentUserId: 1,
              inputReserve: 0,
              initialAroundId: null,
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
          chatId: 90,
          entityId: 2,
          entityType: EntityType.server,
          lastIdMessage: 0,
          limit: 25,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(members.entityId, 2);
      expect(members.entityType, EntityType.server);
      expect(members.chatId, 90);
      expect(members.readId, 11);

      await tester.pumpWidget(const CupertinoApp(home: SizedBox.shrink()));
      await tester.runAsync(() async {
        await messageBloc.close();
        await chatBloc.close();
      });
      bus.dispose();
      await sl.reset();
    },
  );
}

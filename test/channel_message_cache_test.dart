import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/responses/message_response.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/chat/chat_screen.dart';
import 'package:flutter_test/flutter_test.dart';

class _Messages implements MessageRepository {
  final Map<int, MessagesResponse> cache = {};
  Completer<void>? release;
  int getCalls = 0;
  int responseId = 40;
  List<Message>? responseMessages;

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
    getCalls++;
    await release?.future;
    final response = MessagesResponse(
      messages:
          responseMessages ??
          [Message(id: responseId, chatId: chatId, text: 'Ответ сервера')],
      actions: const [],
    );
    if (aroundId == null) cache[chatId] = response;
    return Right(response);
  }

  @override
  MessagesResponse? getCached(int chatId) => cache[chatId];

  @override
  void cacheMessages(int chatId, List<Message> messages) =>
      cache[chatId] = MessagesResponse(messages: messages, actions: const []);

  @override
  void clearAllCache() => cache.clear();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Chats implements ChatRepository {
  int? currentId;

  @override
  bool isCurrentChat(int chatId) => currentId == chatId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reactions implements ReactionsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'fully read channel opens the latest page despite saved position',
    () async {
      final chat = Chat(
        id: 90,
        name: 'Канал',
        type: ChatType.channel,
        newMessagesCount: 0,
      );
      final messages = _Messages()..responseId = 50;
      messages.cacheMessages(90, const [Message(id: 40, chatId: 90)]);
      final bus = WsEventBus();
      final bloc = MessageBloc(messages, _Reactions(), _Chats(), bus);

      final savedPosition = initialPositionForChat(chat, 40);
      expect(savedPosition, isNull);
      final loaded = bloc.stream.firstWhere((state) => state is MessageLoaded);
      bloc.add(
        GetMessages(
          chatId: 90,
          entityId: 2,
          entityType: EntityType.server,
          lastIdMessage: 0,
          aroundId: savedPosition,
        ),
      );
      await loaded;
      expect((bloc.state as MessageLoaded).messages.first.id, 50);
      expect(messages.getCalls, 1);
      expect(
        initialPositionForChat(chat.copyWith(newMessagesCount: 2), 40),
        isNull,
      );
      expect(
        initialPositionForChat(chat.copyWith(type: ChatType.personal), 40),
        40,
      );

      await bloc.close();
      bus.dispose();
    },
  );

  test(
    'reopening around a cached channel message keeps the whole page',
    () async {
      final messages = _Messages();
      final page = List.generate(
        25,
        (index) => Message(id: 25 - index, chatId: 90),
      );
      messages.cacheMessages(90, page);
      final bus = WsEventBus();
      final bloc = MessageBloc(messages, _Reactions(), _Chats(), bus);

      for (var attempt = 0; attempt < 3; attempt++) {
        final loaded = bloc.stream.firstWhere(
          (state) => state is MessageLoaded,
        );
        bloc.add(
          GetMessages(
            chatId: 90,
            entityId: 2,
            entityType: EntityType.server,
            lastIdMessage: 0,
            aroundId: 25,
          ),
        );
        await loaded;
        expect((bloc.state as MessageLoaded).messages.length, 25);
        expect(messages.getCached(90)!.messages.length, 25);
      }
      expect(messages.getCalls, 0);

      await bloc.close();
      bus.dispose();
    },
  );

  test('server around response is not cut in half', () async {
    final messages = _Messages()
      ..responseMessages = List.generate(
        25,
        (index) => Message(id: 25 - index, chatId: 90),
      );
    final bus = WsEventBus();
    final bloc = MessageBloc(messages, _Reactions(), _Chats(), bus);

    final loaded = bloc.stream.firstWhere((state) => state is MessageLoaded);
    bloc.add(
      GetMessages(
        chatId: 90,
        entityId: 2,
        entityType: EntityType.server,
        lastIdMessage: 0,
        aroundId: 25,
      ),
    );
    await loaded;
    expect((bloc.state as MessageLoaded).messages.length, 25);
    expect(messages.getCached(90)!.messages.length, 25);

    await bloc.close();
    bus.dispose();
  });

  test('server around response preserves previously cached messages', () async {
    final messages = _Messages()
      ..responseMessages = List.generate(
        25,
        (index) => Message(id: 50 - index, chatId: 90),
      );
    messages.cacheMessages(
      90,
      List.generate(25, (index) => Message(id: 100 - index, chatId: 90)),
    );
    final bus = WsEventBus();
    final bloc = MessageBloc(messages, _Reactions(), _Chats(), bus);

    final loaded = bloc.stream.firstWhere((state) => state is MessageLoaded);
    bloc.add(
      GetMessages(
        chatId: 90,
        entityId: 2,
        entityType: EntityType.server,
        lastIdMessage: 0,
        aroundId: 50,
      ),
    );
    await loaded;
    expect((bloc.state as MessageLoaded).messages.length, 25);
    expect(messages.getCached(90)!.messages.length, 50);
    expect(messages.getCached(90)!.messages.first.id, 100);

    await bloc.close();
    bus.dispose();
  });

  test(
    'message received during channel load survives stale response',
    () async {
      final messages = _Messages()..release = Completer<void>();
      final chats = _Chats()..currentId = 90;
      final bus = WsEventBus();
      final bloc = MessageBloc(messages, _Reactions(), chats, bus)
        ..setupListeners();

      final loading = bloc.stream.firstWhere(
        (state) => state is MessageLoading,
      );
      bloc.add(
        GetMessages(
          chatId: 90,
          entityId: 2,
          entityType: EntityType.server,
          lastIdMessage: 0,
        ),
      );
      await loading;
      bus.dispatch(
        WsEvent(
          table: 'Message',
          action: ActionType.create,
          data: {
            'chatId': 90,
            'message': {'id': 41, 'text': 'Новое'},
          },
          isSelf: false,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final loaded = bloc.stream.firstWhere(
        (state) => state is MessageLoaded && state.messages.first.id == 41,
      );
      messages.release!.complete();
      await loaded;
      expect(messages.getCached(90)!.messages.map((m) => m.id), [41, 40]);

      await bloc.close();
      bus.dispose();
    },
  );

  test(
    'channel WebSocket message updates cache and survives reopening',
    () async {
      final messages = _Messages();
      final chats = _Chats()..currentId = 90;
      final bus = WsEventBus();
      final bloc = MessageBloc(messages, _Reactions(), chats, bus)
        ..setupListeners();

      bloc.add(
        GetMessages(
          chatId: 90,
          entityId: 2,
          entityType: EntityType.server,
          lastIdMessage: 0,
        ),
      );
      await bloc.stream.firstWhere((state) => state is MessageLoaded);

      final incoming = bloc.stream.firstWhere(
        (state) => state is MessageLoaded && state.messages.first.id == 41,
      );
      bus.dispatch(
        WsEvent(
          table: 'Message',
          action: ActionType.create,
          data: {
            'chatId': '90',
            'message': {'id': '41', 'text': 'Новое'},
          },
          isSelf: false,
        ),
      );
      await incoming;
      expect(messages.getCached(90)!.messages.map((m) => m.id), [41, 40]);

      chats.currentId = null;
      bus.dispatch(
        WsEvent(
          table: 'Message',
          action: ActionType.create,
          data: {
            'chatId': 90,
            'message': {'id': 42, 'text': 'Пока чат закрыт'},
          },
          isSelf: false,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(messages.getCached(90)!.messages.map((m) => m.id), [42, 41, 40]);

      chats.currentId = 90;
      final reopened = bloc.stream.firstWhere(
        (state) => state is MessageLoaded && state.messages.first.id == 42,
      );
      bloc.add(
        GetMessages(
          chatId: 90,
          entityId: 2,
          entityType: EntityType.server,
          lastIdMessage: 0,
          aroundId: 40,
        ),
      );
      await reopened;
      expect(messages.getCalls, 1);

      final edited = bloc.stream.firstWhere(
        (state) =>
            state is MessageLoaded && state.messages.first.text == 'Изменено',
      );
      bus.dispatch(
        WsEvent(
          table: 'Message',
          action: ActionType.update,
          data: {
            'chatId': '90',
            'message': {'id': '42', 'text': 'Изменено'},
          },
          isSelf: false,
        ),
      );
      await edited;

      final deleted = bloc.stream.firstWhere(
        (state) => state is MessageLoaded && state.messages.first.id == 41,
      );
      bus.dispatch(
        WsEvent(
          table: 'Message',
          action: ActionType.delete,
          data: {'chatId': '90', 'messageId': '42'},
          isSelf: false,
        ),
      );
      await deleted;

      bus.dispatch(
        WsEvent(
          table: 'Message',
          action: ActionType.create,
          data: {
            'chatId': 91,
            'message': {'id': 100, 'text': 'Другой канал'},
          },
          isSelf: false,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(messages.getCached(91)?.messages.single.id, 100);

      await bloc.close();
      bus.dispose();
    },
  );
}

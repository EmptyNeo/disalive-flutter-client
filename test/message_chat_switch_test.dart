import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/history_action.dart';
import 'package:disalive/domain/models/responses/message_response.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Messages implements MessageRepository {
  final firstChat = Completer<Either<Failure, MessagesResponse>>();
  final cached = <int, MessagesResponse>{};
  int firstChatCalls = 0;

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
  ) {
    if (chatId == 1 && firstChatCalls++ == 0) return firstChat.future;
    return Future.value(
      Right(
        MessagesResponse(
          messages: [Message(id: chatId * 10, chatId: chatId)],
          actions: const [],
        ),
      ),
    );
  }

  @override
  MessagesResponse? getCached(int chatId) => cached[chatId];

  @override
  void cacheMessages(int chatId, List<Message> messages) {
    cached[chatId] = MessagesResponse(
      messages: messages,
      actions: cached[chatId]?.actions ?? const [],
    );
  }

  @override
  void cacheActions(int chatId, List<HistoryAction> actions) {
    cached[chatId] = MessagesResponse(
      messages: cached[chatId]?.messages ?? const [],
      actions: actions,
    );
  }

  @override
  void clearAllCache() => cached.clear();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reactions implements ReactionsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Chats implements ChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'late response from previous chat never replaces the active chat',
    () async {
      final repository = _Messages();
      final bus = WsEventBus();
      final bloc = MessageBloc(repository, _Reactions(), _Chats(), bus);

      bloc.add(
        GetMessages(
          chatId: 1,
          entityId: 1,
          entityType: EntityType.chat,
          lastIdMessage: 0,
        ),
      );
      await bloc.stream.firstWhere(
        (state) => state is MessageLoading && state.chatId == 1,
      );

      bloc.add(
        GetMessages(
          chatId: 2,
          entityId: 2,
          entityType: EntityType.chat,
          lastIdMessage: 0,
        ),
      );
      await bloc.stream.firstWhere(
        (state) => state is MessageLoaded && state.chatId == 2,
      );
      expect((bloc.state as MessageLoaded).messages.single.chatId, 2);

      repository.firstChat.complete(
        Right(
          MessagesResponse(
            messages: const [Message(id: 10, chatId: 1)],
            actions: const [],
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.chatId, 2);
      expect((bloc.state as MessageLoaded).messages.single.chatId, 2);

      bloc.add(
        GetMessages(
          chatId: 1,
          entityId: 1,
          entityType: EntityType.chat,
          lastIdMessage: 0,
        ),
      );
      await bloc.stream.firstWhere(
        (state) => state is MessageLoaded && state.chatId == 1,
      );
      expect((bloc.state as MessageLoaded).messages.single.chatId, 1);

      await bloc.close();
      bus.dispose();
    },
  );

  test('closing an overlaid chat restores its previous cached history', () async {
    final repository = _Messages();
    repository.firstChat.complete(
      Right(
        MessagesResponse(
          messages: const [Message(id: 10, chatId: 1)],
          actions: const [],
        ),
      ),
    );
    final bus = WsEventBus();
    final bloc = MessageBloc(repository, _Reactions(), _Chats(), bus);

    bloc.add(GetMessages(
      chatId: 1,
      entityId: 1,
      entityType: EntityType.chat,
      lastIdMessage: 0,
    ));
    final previous = await bloc.stream.firstWhere(
      (state) => state is MessageLoaded && state.chatId == 1,
    ) as MessageLoaded;

    bloc.add(GetMessages(
      chatId: 2,
      entityId: 2,
      entityType: EntityType.chat,
      lastIdMessage: 0,
    ));
    await bloc.stream.firstWhere(
      (state) => state is MessageLoaded && state.chatId == 2,
    );
    repository.cacheMessages(1, const [Message(id: 11, chatId: 1)]);

    bloc.add(RestoreChatMessages(
      chatId: 1,
      entityId: 1,
      entityType: EntityType.chat,
      previousState: previous,
    ));
    final restored = await bloc.stream.firstWhere(
      (state) => state is MessageLoaded && state.chatId == 1,
    ) as MessageLoaded;
    expect(restored.messages.single.id, 11);

    await bloc.close();
    bus.dispose();
  });
}

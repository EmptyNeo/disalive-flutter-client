import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/history_action.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/responses/message_response.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/chat/widgets/messages_list.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Messages implements MessageRepository {
  final initial = Completer<MessagesResponse>();
  final creation = Completer<Either<Failure, bool>>();
  MessagesResponse? cached;

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
    if (lastIdMessage != 0) {
      return const Right(
        MessagesResponse(messages: [Message(id: 10, chatId: 1)], actions: []),
      );
    }
    final response = await initial.future;
    cached =
        response; // The real repository replaces the cache on initial load.
    return Right(response);
  }

  @override
  Future<Either<Failure, bool>> create(
    int chatId,
    int entityId,
    EntityType entityType,
    String localGeneratedId,
    Message message,
    String? filePath,
    dynamic typeFile,
    int? packId,
  ) => creation.future;

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
  bool isCurrentChat(int chatId) => chatId == 1;

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
  test('old history action skips an unsent message', () {
    const messages = [
      Message(localGeneratedId: 'pending-1'),
      Message(id: 12),
      Message(id: 11),
    ];
    expect(
      historyActionIndexInMessages(messages, 11, hasMoreMessages: true),
      2,
    );
    expect(
      historyActionIndexInMessages(
        const [Message(localGeneratedId: 'pending-1')],
        11,
        hasMoreMessages: false,
      ),
      0,
    );
  });

  test('sending keeps older messages and actions until delivery', () async {
    final repo = _Messages();
    final bus = WsEventBus();
    final bloc = MessageBloc(repo, _Reactions(), _Chats(), bus);
    bloc.add(
      GetMessages(
        chatId: 1,
        entityId: 1,
        entityType: EntityType.chat,
        lastIdMessage: 0,
        limit: 2,
      ),
    );
    await bloc.stream.firstWhere((state) => state is MessageLoading);

    bloc.add(
      CreateMessage(
        chatId: 1,
        entityId: 1,
        entityType: EntityType.chat,
        localGeneratedId: 'pending-1',
        message: const Message(
          chatId: 1,
          localGeneratedId: 'pending-1',
          text: 'pending',
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    repo.initial.complete(
      const MessagesResponse(
        messages: [Message(id: 12, chatId: 1), Message(id: 11, chatId: 1)],
        actions: [HistoryAction(id: 1, lastIdMessage: 11)],
      ),
    );
    await bloc.stream.firstWhere((state) => state is MessageLoaded);
    var loaded = bloc.state as MessageLoaded;
    expect(loaded.messages.map((m) => m.localGeneratedId ?? m.id), [
      'pending-1',
      12,
      11,
    ]);
    expect(loaded.actions.single.id, 1);

    bloc.add(
      GetMessages(
        chatId: 1,
        entityId: 1,
        entityType: EntityType.chat,
        lastIdMessage: 11,
        limit: 2,
      ),
    );
    await bloc.stream.firstWhere(
      (state) =>
          state is MessageLoaded && state.messages.any((m) => m.id == 10),
    );
    loaded = bloc.state as MessageLoaded;
    expect(loaded.messages.map((m) => m.localGeneratedId ?? m.id), [
      'pending-1',
      12,
      11,
      10,
    ]);
    expect(loaded.actions.single.id, 1);

    bloc.add(
      CreateMessage(
        chatId: 1,
        entityId: 1,
        entityType: EntityType.chat,
        localGeneratedId: 'pending-1',
        message: const Message(id: 13, chatId: 1, text: 'pending'),
        isWs: true,
      ),
    );
    await bloc.stream.firstWhere(
      (state) =>
          state is MessageLoaded && state.messages.any((m) => m.id == 13),
    );
    loaded = bloc.state as MessageLoaded;
    expect(loaded.messages.map((m) => m.id), [13, 12, 11, 10]);
    expect(loaded.actions.single.id, 1);

    repo.creation.complete(const Right(true));
    await bloc.close();
    bus.dispose();
  });
}

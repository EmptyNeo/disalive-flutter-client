import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/responses/message_response.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Messages implements MessageRepository {
  MessagesResponse? cached;
  int calls = 0;

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
    calls++;
    return Right(
      MessagesResponse(
        messages: lastIdMessage == 0
            ? [for (var id = 25; id >= 1; id--) Message(id: id, chatId: chatId)]
            : const [],
        actions: const [],
      ),
    );
  }

  @override
  MessagesResponse? getCached(int chatId) => cached;

  @override
  void cacheMessages(int chatId, List<Message> messages) =>
      cached = MessagesResponse(messages: messages, actions: const []);

  @override
  void clearAllCache() => cached = null;

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
  test('older pagination stops after empty page', () async {
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
    await bloc.stream.firstWhere((state) => state is MessageLoaded);
    expect((bloc.state as MessageLoaded).hasMoreMessages, isTrue);

    bloc.add(
      GetMessages(
        chatId: 1,
        entityId: 1,
        entityType: EntityType.chat,
        lastIdMessage: 1,
      ),
    );
    await bloc.stream.firstWhere(
      (state) => state is MessageLoaded && !state.hasMoreMessages,
    );
    expect(repository.calls, 2);

    bloc.add(
      GetMessages(
        chatId: 1,
        entityId: 1,
        entityType: EntityType.chat,
        lastIdMessage: 1,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repository.calls, 2);
    await bloc.close();
    bus.dispose();
  });
}

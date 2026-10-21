import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/reaction_message.dart';
import 'package:disalive/domain/models/responses/message_response.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Messages implements MessageRepository {
  MessagesResponse? cached;
  final initial = const Message(
    id: 1,
    chatId: 2,
    reactions: [
      ReactionMessage(
        messageId: 1,
        nameReaction: '👍',
        amount: 1,
        hasUserReaction: true,
      ),
    ],
  );

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
  ) async => Right(MessagesResponse(messages: [initial], actions: const []));

  @override
  MessagesResponse? getCached(int chatId) => cached;

  @override
  void cacheMessages(int chatId, List<Message> messages) =>
      cached = MessagesResponse(messages: messages, actions: const []);

  @override
  void cacheActions(int chatId, actions) {}

  @override
  void clearAllCache() => cached = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Chats implements ChatRepository {
  @override
  bool isCurrentChat(int chatId) => chatId == 2;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reactions implements ReactionsRepository {
  @override
  Future<Either<Failure, bool>> toggleReaction({
    required int chatId,
    required int entityId,
    required EntityType entityType,
    required int messageId,
    required String nameReaction,
  }) async => const Right(true);
}

Future<void> _load(MessageBloc bloc) async {
  final loaded = bloc.stream.firstWhere((state) => state is MessageLoaded);
  bloc.add(
    GetMessages(
      chatId: 2,
      entityId: 2,
      entityType: EntityType.chat,
      lastIdMessage: 0,
    ),
  );
  await loaded;
}

void main() {
  test(
    'optimistic toggle removes the last reaction from state and cache',
    () async {
      final messages = _Messages();
      final bus = WsEventBus();
      final bloc = MessageBloc(messages, _Reactions(), _Chats(), bus);
      await _load(bloc);

      final updated = bloc.stream.firstWhere(
        (state) => state is MessageLoaded && !state.messages.first.hasReactions,
      );
      bloc.add(
        ToggleReaction(
          chatId: 2,
          entityId: 2,
          entityType: EntityType.chat,
          messageId: 1,
          nameReaction: '👍',
        ),
      );
      await updated;

      expect((bloc.state as MessageLoaded).messages.first.reactions, isNull);
      expect(messages.cached!.messages.first.reactions, isNull);
      await bloc.close();
      bus.dispose();
    },
  );

  test('websocket removal clears the last reaction', () async {
    final messages = _Messages();
    final bus = WsEventBus();
    final bloc = MessageBloc(messages, _Reactions(), _Chats(), bus);
    await _load(bloc);

    final updated = bloc.stream.firstWhere(
      (state) => state is MessageLoaded && !state.messages.first.hasReactions,
    );
    bloc.add(
      UpdateReactionFromWs(
        chatId: 2,
        messageId: 1,
        nameReaction: '👍',
        amount: 0,
        hasUserReaction: false,
      ),
    );
    await updated;

    expect((bloc.state as MessageLoaded).messages.first.reactions, isNull);
    expect(messages.cached!.messages.first.reactions, isNull);
    await bloc.close();
    bus.dispose();
  });
}

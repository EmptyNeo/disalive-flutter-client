// lib/presentation/features/message/bloc/message_event.dart
part of 'message_bloc.dart';

@immutable
abstract class MessageEvent {}

class RestoreChatMessages extends MessageEvent {
  RestoreChatMessages({
    required this.chatId,
    required this.entityId,
    required this.entityType,
    required this.previousState,
  });

  final int chatId;
  final int entityId;
  final EntityType entityType;
  final MessageLoaded previousState;
}

class UpsertHistoryAction extends MessageEvent {
  final int chatId;
  final HistoryAction action;

  UpsertHistoryAction({required this.chatId, required this.action});
}

class GetMessages extends MessageEvent {
  final int chatId;
  final int entityId;
  final EntityType entityType;
  final int lastIdMessage;
  final int limit;
  final int? aroundId;
  final int? newerThanId;
  final String? searchQuery;
  final bool showed;

  GetMessages({
    required this.chatId,
    required this.entityId,
    required this.entityType,
    required this.lastIdMessage,
    this.limit = 25,
    this.newerThanId,
    this.aroundId,
    this.searchQuery,
    this.showed = true,
  });
}

// В MessageEvent:
class CreateMessage extends MessageEvent {
  final int chatId;
  final int entityId;
  final EntityType entityType;
  final String localGeneratedId;
  final Message message;
  final SymbolData? symbolData;
  final bool isWs;

  CreateMessage({
    required this.chatId,
    required this.entityId,
    required this.entityType,
    required this.localGeneratedId,
    required this.message,
    this.symbolData,
    this.isWs = false,
  });
}

class UpdateMessage extends MessageEvent {
  final int chatId;
  final int entityId;
  final EntityType entityType;
  final Message message;
  final bool isWs;

  UpdateMessage({
    required this.chatId,
    required this.entityId,
    required this.entityType,
    required this.message,
    this.isWs = false,
  });
}
// lib/presentation/features/message/bloc/message_event.dart

class DeleteMessage extends MessageEvent {
  final int chatId;
  final int entityId;
  final EntityType entityType;
  final int? messageId;
  final String? localGeneratedId;
  final bool isWs;

  DeleteMessage({
    required this.chatId,
    required this.entityId,
    required this.entityType,
    this.messageId,
    this.localGeneratedId,
    this.isWs = false,
  });
}

class ToggleReaction extends MessageEvent {
  final int chatId;
  final int entityId;
  final EntityType entityType;
  final int messageId;
  final String nameReaction;

  ToggleReaction({
    required this.chatId,
    required this.entityId,
    required this.entityType,
    required this.messageId,
    required this.nameReaction,
  });
}

class UpdateReactionFromWs extends MessageEvent {
  final int chatId;
  final int messageId;
  final String nameReaction;
  final int amount;
  final bool hasUserReaction;
  final int? userId;

  UpdateReactionFromWs({
    required this.chatId,
    required this.messageId,
    required this.nameReaction,
    required this.amount,
    required this.hasUserReaction,
    this.userId,
  });
}

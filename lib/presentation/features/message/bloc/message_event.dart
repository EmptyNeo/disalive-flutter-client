// lib/presentation/features/message/bloc/message_event.dart
part of 'message_bloc.dart';

@immutable
abstract class MessageEvent {}

class GetMessages extends MessageEvent {
  final int chatId;
  final int entityId;
  final EntityType entityType;
  final int lastIdMessage;
  final int limit;
  final int? aroundId;
  final int? neverThanId;
  final String? searchQuery;

  GetMessages({
    required this.chatId,
    required this.entityId,
    required this.entityType,
    required this.lastIdMessage,
    this.limit = 30,
    this.neverThanId,
    this.aroundId,
    this.searchQuery,
  });
}
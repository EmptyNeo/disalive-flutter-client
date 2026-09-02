// lib/domain/repositories/message_repository.dart
import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/responses/message_response.dart';

abstract class MessageRepository {
  Future<Either<Failure, MessagesResponse>> get(
    int chatId,
    int entityId,
    EntityType entityType,
    int limit,
    int lastIdMessage,
    int? aroundId,
    int? neverThanId,
    String? searchQuery,
  );

  Future<Either<Failure, bool>> create(
    int chatId,
    int entityId,
    EntityType entityType,
    String localGeneratedId,
    String text,
    int? answerMessageId,
    int? forwardMessageId,
  );

  Future<Either<Failure, bool>> update(
    int chatId,
    int entityId,
    EntityType entityType,
    int messageId,
    String text,
  );

  Future<Either<Failure, bool>> delete(
    int chatId,
    int entityId,
    EntityType entityType,
    int messageId,
  );

  MessagesResponse? getCached(int chatId);

  void clearCache(int chatId);

  void clearAllCache();
}

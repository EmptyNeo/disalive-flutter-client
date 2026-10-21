import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/call_data.dart';
import 'package:disalive/domain/models/entity_key.dart';

abstract class CallsRepository {
  Future<Either<Failure, CallToken>> getToken({
    required int chatId,
    required EntityKey entityKey,
    int? lastIdMessage,
  });

  /// Если [chatId] не задан, возвращает участников всех каналов сервера.
  Future<Either<Failure, CallParticipants>> getParticipants({
    required EntityKey entityKey,
    int? chatId,
  });

  /// Без [expiresAt]: 0 минут означает удаление только из текущего звонка.
  /// При [expiresAt] отправляется ISO дата, без поля timeoutMinutes.
  Future<Either<Failure, CallBan>> kick({
    required int chatId,
    required EntityKey entityKey,
    required int targetUserId,
    int timeoutMinutes = 0,
    DateTime? expiresAt,
  });

  Future<Either<Failure, bool>> unban({
    required EntityKey entityKey,
    required int targetUserId,
  });
}

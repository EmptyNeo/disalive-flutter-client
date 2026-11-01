import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/entity_access.dart';
import 'package:disalive/domain/models/entity_moderation.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/server.dart';

abstract class MembersRepository {
  Future<Either<Failure, Server>> create(int entityId, EntityType entityType);

  Future<Either<Failure, List<Member>>> get(
    int entityId,
    EntityType entityType,
  );

  Future<Either<Failure, bool>> update({
    required int entityId,
    required EntityType entityType,
    int? chatId,
    int? lastIdReadMessage,
    bool toggleMuted = false,
    bool toggleFixed = false,
  });

  Future<Either<Failure, bool>> leave(int entityId, EntityType entityType);

  Future<Either<Failure, bool>> remove(EntityKey entityKey, int userId);

  Future<Either<Failure, bool>> add(int chatId, List<int> userIds);

  Future<Either<Failure, EntityAccess>> checkAccess(EntityKey entityKey);

  Future<Either<Failure, bool>> moderate({
    required EntityKey entityKey,
    required int userId,
    required String action,
    String? expiresAt,
    String? reason,
  });

  Future<Either<Failure, List<EntityModeration>>> getModeration(
    EntityKey entityKey,
  );

  Future<List<Member>> getCached(EntityKey entityKey);

  void updateCache(EntityKey entityKey, List<Member> members);

  void clear();
}

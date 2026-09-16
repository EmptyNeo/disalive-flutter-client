import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/member.dart';

abstract class MembersRepository {
  Future<Either<Failure, List<Member>>> get(
    int entityId,
    EntityType entityType,
  );

  Future<Either<Failure, bool>> update(
    int entityId,
    EntityType entityType,
    int? lastIdReadMessage,
    bool toggleMuted,
    bool toggleFixed,
  );

  Future<Either<Failure, bool>> leave(int entityId, EntityType entityType);

  Future<Either<Failure, bool>> remove(EntityKey entityKey, int userId);

  Future<List<Member>> getCached(EntityKey entityKey);

  void updateCache(EntityKey entityKey, List<Member> members);
}

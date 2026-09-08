import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';

abstract class MembersRepository {
  Future<Either<Failure, bool>> update(
    int entityId,
    EntityType entityType,
    int? lastIdReadMessage,
    bool toggleMuted,
    bool toggleFixed,
  );

  Future<Either<Failure, bool>> leave(int entityId, EntityType entityType);
}

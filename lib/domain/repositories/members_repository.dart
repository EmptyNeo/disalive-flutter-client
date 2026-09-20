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

  Future<List<Member>> getCached(EntityKey entityKey);

  void updateCache(EntityKey entityKey, List<Member> members);

  void clear();
}

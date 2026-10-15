import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/role_member.dart';

abstract class RoleMemberRepository {
  Future<Either<Failure, List<RoleMember>>> get(
    int entityId,
    EntityType entityType,
  );

  /// Creates a role; the server assigns its placeholder name.
  Future<Either<Failure, RoleMember>> create(
    int entityId,
    EntityType entityType,
  );

  /// At least one of name or emoji must be non-empty.
  Future<Either<Failure, RoleMember>> update(
    int roleId,
    int entityId,
    EntityType entityType, {
    String? name,
    String? emoji,
    required Map<String, bool> permissions,
  });

  Future<Either<Failure, bool>> delete(
    int roleId,
    int entityId,
    EntityType entityType,
  );

  Future<Either<Failure, bool>> assign(
    int roleId,
    int entityId,
    EntityType entityType,
    List<int> userIds,
  );

  Future<Either<Failure, bool>> unassign(
    int roleId,
    int entityId,
    EntityType entityType,
    int userId,
  );

  List<RoleMember> getCached(EntityKey entityKey);
  RoleMember? getByIdCached(int roleId);
  void updateCache(EntityKey entityKey, List<RoleMember> roles);
  void clear([EntityKey? entityKey]);
}

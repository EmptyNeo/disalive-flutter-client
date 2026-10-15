import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/invite_data.dart';

abstract class InviteRepository {
  Future<Either<Failure, String>> generateCode();

  Future<Either<Failure, InviteData>> create(
    int entityId,
    EntityType entityType,
    String code, {
    EntityKey? callEntity,
    int maxUsers = 0,
    int? expiresAt,
  });

  /// Public lookup for the invitation page; no session is required.
  Future<Either<Failure, InviteDetails>> getByCode(String code);

  Future<Either<Failure, List<InviteData>>> getForServer(int serverId);

  Future<Either<Failure, InviteAcceptance>> accept(String code);

  Future<Either<Failure, bool>> revoke(int inviteId);

  List<InviteData> getCached(int serverId);
  void updateCache(int serverId, List<InviteData> invites);
  void clear([int? serverId]);
}

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class MembersRepositoryImpl extends MembersRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  final Map<EntityKey, List<Member>> _members = {};

  @override
  Future<Either<Failure, List<Member>>> get(
    int entityId,
    EntityType entityType,
  ) async {
    EntityKey entityKey = EntityKey(entityId: entityId, entityType: entityType);
    final result = await _httpClient.postFormData<List<Member>>(
      endpoint: 'members/get.php',
      data: {'entityId': entityId, 'entityType': entityType.value},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is Map<String, dynamic> && json['members'] is List) {
          return (json['members'] as List)
              .map((e) => Member.fromMap(e as Map<String, dynamic>))
              .toList();
        }
        return <Member>[];
      },
    );

    result.fold((failure) => null, (response) {
      if (_members[entityKey] == null) {
        _members[entityKey] = response;
      }
    });

    return result;
  }

  @override
  Future<Either<Failure, bool>> update(
    int entityId,
    EntityType entityType,
    int? lastIdReadMessage,
    bool toggleMuted,
    bool toggleFixed,
  ) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'members/update.php',
      data: {
        "entityId": entityId,
        "entityType": entityType.value,
        "lastIdReadMessage": lastIdReadMessage,
        "muted": toggleMuted ? "toggle" : null,
        "fixed": toggleFixed ? "toggle" : null,
      },
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        return json is Map<String, dynamic>;
      },
    );

    return result;
  }

  @override
  Future<Either<Failure, bool>> leave(
    int entityId,
    EntityType entityType,
  ) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'members/leave.php',
      data: {"entityId": entityId, "entityType": entityType.value},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        return json is Map<String, dynamic>;
      },
    );

    return result;
  }

  @override
  Future<Either<Failure, bool>> remove(EntityKey entityKey, int userId) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'members/remove.php',
      data: {
        "entityId": entityKey.entityId,
        "entityType": entityKey.entityType.value,
        "userId": userId,
      },
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        return json is Map<String, dynamic>;
      },
    );

    return result;
  }

  @override
  Future<List<Member>> getCached(EntityKey entityKey) async {
    List<Member>? members = _members[entityKey];
    if (members == null) {
      return <Member>[];
    }

    return members;
  }

  @override
  void updateCache(EntityKey entityKey, List<Member> members) {
    _members[entityKey] = members;
  }
}

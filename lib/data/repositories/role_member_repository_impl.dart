import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/domain/repositories/role_member_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class RoleMemberRepositoryImpl implements RoleMemberRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  final Map<EntityKey, List<RoleMember>> _cache = {};

  @override
  Future<Either<Failure, List<RoleMember>>> get(
    int entityId,
    EntityType entityType,
  ) async {
    final result = await _httpClient.postFormData<List<RoleMember>>(
      endpoint: 'roleMembers/get.php',
      data: {'entityId': entityId, 'entityType': entityType.value},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => (json as List)
          .map((item) => RoleMember.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
    result.fold(
      (failure) => null,
      (roles) => updateCache(
        EntityKey(entityId: entityId, entityType: entityType),
        roles,
      ),
    );
    return result;
  }

  @override
  Future<Either<Failure, RoleMember>> create(
    int entityId,
    EntityType entityType,
  ) async {
    final result = await _httpClient.postFormData<RoleMember>(
      endpoint: 'roleMembers/create.php',
      data: {'entityId': entityId, 'entityType': entityType.value},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => RoleMember.fromMap(json as Map<String, dynamic>),
    );
    result.fold(
      (failure) => null,
      (role) =>
          _upsert(EntityKey(entityId: entityId, entityType: entityType), role),
    );
    return result;
  }

  @override
  Future<Either<Failure, RoleMember>> update(
    int roleId,
    int entityId,
    EntityType entityType, {
    String? name,
    String? emoji,
    required Map<String, bool> permissions,
  }) async {
    final result = await _httpClient.postFormData<Map<String, dynamic>>(
      endpoint: 'roleMembers/update.php',
      data: {
        'roleId': roleId,
        'entityId': entityId,
        'entityType': entityType.value,
        'name': ?name,
        'emoji': ?emoji,
        'permissions': jsonEncode(permissions),
      },
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return result.fold((failure) => Left(failure), (response) {
      final previous = getByIdCached(roleId);
      final role = RoleMember.fromMap({
        if (previous != null) ...previous.toMap(),
        'id': roleId,
        'entityId': entityId,
        'entityType': entityType.value,
        ...response,
      });
      _upsert(EntityKey(entityId: entityId, entityType: entityType), role);
      return Right(role);
    });
  }

  @override
  Future<Either<Failure, bool>> delete(
    int roleId,
    int entityId,
    EntityType entityType,
  ) async {
    final result = await _postSuccess('roleMembers/delete.php', {
      'roleId': roleId,
      'entityId': entityId,
      'entityType': entityType.value,
    });
    result.fold((failure) => null, (deleted) {
      if (deleted) {
        _cache[EntityKey(entityId: entityId, entityType: entityType)]
            ?.removeWhere((role) => role.id == roleId);
      }
    });
    return result;
  }

  @override
  Future<Either<Failure, bool>> assign(
    int roleId,
    int entityId,
    EntityType entityType,
    List<int> userIds,
  ) => _postSuccess('roleMembers/assign.php', {
    'roleId': roleId,
    'entityId': entityId,
    'entityType': entityType.value,
    'userIds': jsonEncode(userIds),
  });

  @override
  Future<Either<Failure, bool>> unassign(
    int roleId,
    int entityId,
    EntityType entityType,
    int userId,
  ) => _postSuccess('roleMembers/unassign.php', {
    'roleId': roleId,
    'entityId': entityId,
    'entityType': entityType.value,
    'userId': userId,
  });

  Future<Either<Failure, bool>> _postSuccess(
    String endpoint,
    Map<String, dynamic> data,
  ) => _httpClient.postFormData<bool>(
    endpoint: endpoint,
    data: data,
    apiType: ApiType.v1,
    requireAuth: true,
    fromJson: (json) => json is Map && json['success'] == true,
  );

  void _upsert(EntityKey key, RoleMember role) {
    final roles = _cache[key];
    if (roles == null) return;
    final index = roles.indexWhere((item) => item.id == role.id);
    if (index < 0) {
      roles.add(role);
    } else {
      roles[index] = role;
    }
  }

  @override
  List<RoleMember> getCached(EntityKey entityKey) =>
      List<RoleMember>.unmodifiable(_cache[entityKey] ?? const []);

  @override
  RoleMember? getByIdCached(int roleId) {
    for (final roles in _cache.values) {
      for (final role in roles) {
        if (role.id == roleId) return role;
      }
    }
    return null;
  }

  @override
  void updateCache(EntityKey entityKey, List<RoleMember> roles) {
    _cache[entityKey] = List<RoleMember>.from(roles);
  }

  @override
  void clear([EntityKey? entityKey]) {
    if (entityKey == null) {
      _cache.clear();
    } else {
      _cache.remove(entityKey);
    }
  }
}

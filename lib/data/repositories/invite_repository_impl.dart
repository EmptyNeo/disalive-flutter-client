import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/invite_data.dart';
import 'package:disalive/domain/repositories/invite_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class InviteRepositoryImpl implements InviteRepository {
  final HttpClientService _httpClient;
  final Map<int, List<InviteData>> _cache = {};

  InviteRepositoryImpl({HttpClientService? httpClient})
    : _httpClient = httpClient ?? sl<HttpClientService>();

  @override
  Future<Either<Failure, String>> generateCode() => _httpClient.get<String>(
    endpoint: 'invites/generate.php',
    apiType: ApiType.v1,
    requireAuth: true,
    fromJson: (json) => json as String,
  );

  @override
  Future<Either<Failure, InviteData>> create(
    int entityId,
    EntityType entityType,
    String code, {
    EntityKey? callEntity,
    int maxUsers = 0,
    int? expiresAt,
  }) async {
    final result = await _httpClient.postFormData<InviteData>(
      endpoint: 'invites/create.php',
      data: {
        'entityId': entityId,
        'entityType': entityType.value,
        'code': code,
        'maxUsers': maxUsers,
        'expiresAt': ?expiresAt,
        if (callEntity != null) ...{
          'callEntity[id]': callEntity.entityId,
          'callEntity[type]': callEntity.entityType.value,
        },
      },
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => InviteData.fromMap({
        'entityId': entityId,
        'entityType': entityType.value,
        'code': code,
        ...json as Map<String, dynamic>,
      }),
    );
    result.fold((failure) => null, (invite) {
      final cached = _cache[entityId];
      if (cached == null || invite.id == null) return;
      final index = cached.indexWhere((item) => item.id == invite.id);
      if (index < 0) {
        cached.add(invite);
      } else {
        cached[index] = invite;
      }
    });
    return result;
  }

  @override
  Future<Either<Failure, InviteDetails>> getByCode(String code) =>
      _httpClient.get<InviteDetails>(
        endpoint: 'invites/get.php',
        queryParams: {'code': code},
        apiType: ApiType.v1,
        requireAuth: false,
        fromJson: (json) => InviteDetails.fromMap(json as Map<String, dynamic>),
      );

  @override
  Future<Either<Failure, List<InviteData>>> getForServer(int serverId) async {
    final result = await _httpClient.postFormData<List<InviteData>>(
      endpoint: 'invites/get.php?entityId=$serverId',
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => (json as List)
          .map((item) => InviteData.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
    result.fold((failure) => null, (invites) => updateCache(serverId, invites));
    return result;
  }

  @override
  Future<Either<Failure, InviteAcceptance>> accept(String code) =>
      _httpClient.postFormData<InviteAcceptance>(
        endpoint: 'invites/accept.php',
        data: {'code': code},
        apiType: ApiType.v1,
        requireAuth: true,
        fromJson: (json) =>
            InviteAcceptance.fromMap(json as Map<String, dynamic>),
      );

  @override
  Future<Either<Failure, bool>> revoke(int inviteId) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'invites/revoke.php',
      data: {'id': inviteId},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => json is Map && json['success'] == true,
    );
    result.fold((failure) => null, (revoked) {
      if (!revoked) return;
      for (final invites in _cache.values) {
        final index = invites.indexWhere((invite) => invite.id == inviteId);
        if (index >= 0) invites[index] = invites[index].copyWith(revoked: true);
      }
    });
    return result;
  }

  @override
  List<InviteData> getCached(int serverId) =>
      List<InviteData>.unmodifiable(_cache[serverId] ?? const []);

  @override
  void updateCache(int serverId, List<InviteData> invites) {
    _cache[serverId] = List<InviteData>.from(invites);
  }

  @override
  void clear([int? serverId]) {
    if (serverId == null) {
      _cache.clear();
    } else {
      _cache.remove(serverId);
    }
  }
}

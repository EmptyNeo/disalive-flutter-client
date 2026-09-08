import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class MembersRepositoryImpl extends MembersRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();

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
}

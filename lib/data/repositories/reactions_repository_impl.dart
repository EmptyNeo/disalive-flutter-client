// lib/data/repositories/reactions_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class ReactionsRepositoryImpl implements ReactionsRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();

  @override
  Future<Either<Failure, bool>> toggleReaction({
    required int chatId,
    required int entityId,
    required EntityType entityType,
    required int messageId,
    required String nameReaction,
  }) async {
    return await _httpClient.postFormData<bool>(
      endpoint: 'reactions/toggle.php',
      data: {
        'entityId': entityId,
        'entityType': entityType.value,
        'messageId': messageId,
        'nameReaction': nameReaction,
      },
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        return json['success'] == true;
      },
    );
  }
}

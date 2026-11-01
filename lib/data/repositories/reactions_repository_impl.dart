// lib/data/repositories/reactions_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/responses/reaction_summary_page.dart';
import 'package:disalive/domain/models/responses/reaction_users_page.dart';
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

  @override
  Future<Either<Failure, ReactionSummaryPage>> getByMessage({
    required int messageId,
    required int entityId,
    required EntityType entityType,
    int cursor = 0,
    int limit = 30,
  }) => _httpClient.postFormData<ReactionSummaryPage>(
    endpoint: 'reactions/getByMessage.php',
    data: {
      'messageId': messageId,
      'entityId': entityId,
      'entityType': entityType.value,
      'cursor': cursor,
      'limit': limit,
    },
    apiType: ApiType.v1,
    requireAuth: true,
    fromJson: (data) {
      return ReactionSummaryPage.fromResponse(data);
    },
  );

  @override
  Future<Either<Failure, ReactionUsersPage>> getUsersByMessage({
    required int messageId,
    required int entityId,
    required EntityType entityType,
    required String nameReaction,
    int cursor = 0,
    int limit = 30,
  }) => _httpClient.postFormData<ReactionUsersPage>(
    endpoint: 'reactions/getByMessage.php',
    data: {
      'messageId': messageId,
      'entityId': entityId,
      'entityType': entityType.value,
      'nameReaction': nameReaction,
      'cursor': cursor,
      'limit': limit,
    },
    apiType: ApiType.v1,
    requireAuth: true,
    fromJson: (data) {
      return ReactionUsersPage.fromResponse(data);
    },
  );
}

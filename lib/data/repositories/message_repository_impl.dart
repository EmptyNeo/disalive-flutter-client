// lib/data/repositories/message_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/responses/message_response.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class MessageRepositoryImpl implements MessageRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  final Map<int, MessagesResponse> _messages = {};

  @override
  Future<Either<Failure, MessagesResponse>> get(
      int chatId,
      int entityId,
      EntityType entityType,
      int limit,
      int lastIdMessage,
      int? aroundId,
      int? neverThanId,
      String? searchQuery,
      ) async {
    final result = await _httpClient.postFormData<MessagesResponse>(
      endpoint: 'messages/get.php',
      data: {
        'chatId': chatId,
        'entityId': entityId,
        'entityType': entityType.value,
        'limit': limit,
        'lastIdMessage': lastIdMessage,
        'aroundId': aroundId,
        'neverThanId': neverThanId,
        'searchQuery': searchQuery,
      },
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return MessagesResponse.fromMap(json);
        }
        return const MessagesResponse(messages: [], actions: []);
      },
    );

    // Кэшируем только первую загрузку
    result.fold(
          (failure) => null,
          (response) {
        if (lastIdMessage == 0 &&
            aroundId == null &&
            neverThanId == null &&
            searchQuery == null) {
          _messages[chatId] = response;
        }
      },
    );

    return result;
  }

  @override
  MessagesResponse? getCached(int chatId) {
    return _messages[chatId];
  }

  @override
  void clearCache(int chatId) {
    _messages.remove(chatId);
  }

  @override
  void clearAllCache() {
    _messages.clear();
  }
}
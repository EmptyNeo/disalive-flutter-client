// lib/data/repositories/message_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/message.dart';
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

    result.fold((failure) => null, (response) {
      if (lastIdMessage == 0 &&
          aroundId == null &&
          neverThanId == null &&
          searchQuery == null) {
        _messages[chatId] = response;
      }
    });

    return result;
  }

  @override
  Future<Either<Failure, bool>> create(
    int chatId,
    int entityId,
    EntityType entityType,
    String localGeneratedId,
    String text,
    int? answerMessageId,
    int? forwardMessageId,
  ) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'messages/create.php',
      data: {
        'chatId': chatId,
        'entityId': entityId,
        'entityType': entityType.value,
        'localGeneratedId': localGeneratedId,
        'text': text,
        'answerMessageId': answerMessageId,
        'forwardMessageId': forwardMessageId,
      },
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        bool success = json['success'] == true;
        if (success) {
          final newMessage = Message.fromMap(json['message']);
          final messages = _messages[chatId]?.messages;

          if (messages != null) {
            final exists = messages.any((m) => m.id == newMessage.id);
            if (!exists) {
              messages.add(newMessage);
            }
          }
        }
        return success;
      },
    );

    return result;
  }

  @override
  Future<Either<Failure, bool>> update(
    int chatId,
    int entityId,
    EntityType entityType,
    int messageId,
    String text,
  ) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'messages/update.php',
      data: {
        'id': messageId,
        'chatId': chatId,
        'entityId': entityId,
        'entityType': entityType.value,
        'text': text,
      },
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        bool success = json['success'] == true;
        if (success && json['message'] != null) {
          final updatedMessage = Message.fromMap(json['message']);
          final messages = _messages[chatId]?.messages;
          if (messages != null) {
            final index = messages.indexWhere((m) => m.id == messageId);
            if (index != -1) {
              messages[index] = updatedMessage;
            }
          }
        }
        return success;
      },
    );

    return result;
  }

  @override
  Future<Either<Failure, bool>> delete(
    int chatId,
    int entityId,
    EntityType entityType,
    int messageId,
  ) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'messages/delete.php',
      data: {
        'id': messageId,
        'chatId': chatId,
        'entityId': entityId,
        'entityType': entityType.value,
      },
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        bool success = json['success'] == true;
        if (success) {
          _messages[chatId]?.messages.removeWhere((m) => m.id == messageId);
        }
        return success;
      },
    );

    return result;
  }

  @override
  MessagesResponse? getCached(int chatId) {
    return _messages[chatId];
  }

  @override
  void cacheMessages(int chatId, List<Message> messages) {
    final existing = _messages[chatId];
    if (existing != null) {
      _messages[chatId] = existing.copyWith(messages: messages);
    } else {
      _messages[chatId] = MessagesResponse(messages: messages, actions: []);
    }
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

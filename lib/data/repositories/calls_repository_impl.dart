import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/call_data.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/repositories/calls_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class CallsRepositoryImpl implements CallsRepository {
  CallsRepositoryImpl({HttpClientService? httpClient})
    : _httpClient = httpClient ?? sl<HttpClientService>();

  final HttpClientService _httpClient;

  @override
  Future<Either<Failure, CallToken>> getToken({
    required int chatId,
    required EntityKey entityKey,
    int? lastIdMessage,
  }) => _httpClient.postFormData<CallToken>(
    endpoint: 'calls/get.php',
    data: {
      'chatId': chatId,
      'entityId': entityKey.entityId,
      'entityType': entityKey.entityType.value,
      'lastIdMessage': ?lastIdMessage,
    },
    apiType: ApiType.v1,
    requireAuth: true,
    fromJson: (json) => CallToken.fromMap(json as Map<String, dynamic>),
  );

  @override
  Future<Either<Failure, CallParticipants>> getParticipants({
    required EntityKey entityKey,
    int? chatId,
  }) => _httpClient.postFormData<CallParticipants>(
    endpoint: 'calls/participants.php',
    data: {
      'chatId': ?chatId,
      'entityId': entityKey.entityId,
      'entityType': entityKey.entityType.value,
    },
    apiType: ApiType.v1,
    requireAuth: true,
    fromJson: (json) => CallParticipants.fromMap(json as Map<String, dynamic>),
  );

  @override
  Future<Either<Failure, CallBan>> kick({
    required int chatId,
    required EntityKey entityKey,
    required int targetUserId,
    int timeoutMinutes = 0,
    DateTime? expiresAt,
  }) => _httpClient.postFormData<CallBan>(
    endpoint: 'calls/kick.php',
    data: {
      'chatId': chatId,
      'entityId': entityKey.entityId,
      'entityType': entityKey.entityType.value,
      'targetUserId': targetUserId,
      if (expiresAt == null) 'timeoutMinutes': timeoutMinutes,
      if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
    },
    apiType: ApiType.v1,
    requireAuth: true,
    fromJson: (json) => CallBan.fromMap(
      (json as Map<String, dynamic>)['callBan'] as Map<String, dynamic>,
    ),
  );

  @override
  Future<Either<Failure, bool>> unban({
    required EntityKey entityKey,
    required int targetUserId,
  }) => _httpClient.postFormData<bool>(
    endpoint: 'calls/unban.php',
    data: {
      'entityId': entityKey.entityId,
      'entityType': entityKey.entityType.value,
      'targetUserId': targetUserId,
    },
    apiType: ApiType.v1,
    requireAuth: true,
    fromJson: (_) => true,
  );
}

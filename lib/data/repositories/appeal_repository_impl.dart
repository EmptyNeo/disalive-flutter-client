import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/moderation_appeal.dart';
import 'package:disalive/domain/repositories/appeal_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';

class AppealRepositoryImpl implements AppealRepository {
  const AppealRepositoryImpl(this._httpClient, this._storage);

  final HttpClientService _httpClient;
  final SecureStorageService _storage;

  Future<Either<Failure, String>> _sessionKey() async {
    final key = await _storage.getKeySession();
    return key == null || key.isEmpty
        ? const Left(UnauthorizedFailure())
        : Right(key);
  }

  @override
  Future<Either<Failure, List<AppealTarget>>> getTargets() async {
    final session = await _sessionKey();
    return session.fold<Future<Either<Failure, List<AppealTarget>>>>(
      (failure) async => Left<Failure, List<AppealTarget>>(failure),
      (key) => _httpClient.get<List<AppealTarget>>(
        endpoint: 'appeals/index.php',
        apiType: ApiType.v1,
        queryParams: {'action': 'targets'},
        requireAuth: false,
        headers: {'X-Session-Key': key},
        fromJson: (json) => (json as List)
            .map(
              (row) =>
                  AppealTarget.fromMap(Map<String, dynamic>.from(row as Map)),
            )
            .toList(),
      ),
    );
  }

  @override
  Future<Either<Failure, List<ModerationAppeal>>> getMine() async {
    final session = await _sessionKey();
    return session.fold<Future<Either<Failure, List<ModerationAppeal>>>>(
      (failure) async => Left<Failure, List<ModerationAppeal>>(failure),
      (key) => _httpClient.get<List<ModerationAppeal>>(
        endpoint: 'appeals/index.php',
        apiType: ApiType.v1,
        queryParams: {'action': 'mine'},
        requireAuth: false,
        headers: {'X-Session-Key': key},
        fromJson: (json) => (json as List)
            .map(
              (row) => ModerationAppeal.fromMap(
                Map<String, dynamic>.from(row as Map),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Future<Either<Failure, bool>> create(
    AppealTarget target,
    String reason,
  ) async {
    final session = await _sessionKey();
    return session.fold<Future<Either<Failure, bool>>>(
      (failure) async => Left<Failure, bool>(failure),
      (key) => _httpClient.postJson<bool>(
        endpoint: 'appeals/index.php?action=create',
        apiType: ApiType.v1,
        requireAuth: false,
        headers: {'X-Session-Key': key},
        data: {
          'targetType': target.type.value,
          'targetId': target.id,
          'reason': reason.trim(),
        },
        fromJson: (_) => true,
      ),
    );
  }
}

// lib/data/repositories/session_repository_impl.dart
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/session.dart';
import 'package:disalive/domain/repositories/session_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';

class SessionRepositoryImpl implements SessionRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  List<SessionModel>? _sessions;

  @override
  Future<Either<Failure, List<SessionModel>>> get() async {
    final result = await _httpClient.postFormData<List<SessionModel>>(
      endpoint: 'sessions/get.php',
      data: {},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is List) {
          return json
              .map((e) => SessionModel.fromMap(e as Map<String, dynamic>))
              .toList();
        }
        return <SessionModel>[];
      },
    );

    result.fold((failure) => null, (sessions) => _sessions = sessions);

    return result;
  }

  @override
  Future<Either<Failure, bool>> delete(String id, String type) async {
    try {
      final result = await _httpClient.postFormData<Map<String, dynamic>>(
        endpoint: 'sessions/delete.php',
        data: {'id': id, 'type': type},
        apiType: ApiType.v1,
        requireAuth: true,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return result.fold((failure) => Left(failure), (data) {
        _sessions?.removeWhere((session) => session.id == int.tryParse(id));
        return const Right(true);
      });
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  List<SessionModel> getSessions() {
    return _sessions ?? [];
  }

  @override
  Future<int?> getCurrentSessionId() async {
    final cachedSession = _sessions?.firstWhereOrNull(
      (s) => s.isCurrentSession == true,
    );
    if (cachedSession != null) {
      return cachedSession.id;
    }

    final result = await get();
    return result.fold(
      (failure) => null,
      (sessions) =>
          sessions.firstWhereOrNull((s) => s.isCurrentSession == true)?.id,
    );
  }
}

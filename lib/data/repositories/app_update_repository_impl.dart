import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/app_update.dart';
import 'package:disalive/domain/repositories/app_update_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  AppUpdateRepositoryImpl({HttpClientService? httpClient})
    : _httpClient = httpClient ?? sl<HttpClientService>();

  final HttpClientService _httpClient;

  @override
  Future<Either<Failure, AppUpdate>> checkAndroid(String currentVersion) =>
      _httpClient.get<AppUpdate>(
        endpoint: 'update/check.php',
        queryParams: const {'platform': 'android'},
        headers: {'X-Current-Version': currentVersion},
        requireAuth: false,
        fromJson: (json) => AppUpdate.fromMap(
          Map<String, dynamic>.from(json as Map),
        ),
      );
}

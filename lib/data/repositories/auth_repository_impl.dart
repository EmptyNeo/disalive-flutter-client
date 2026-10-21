import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/app_login.dart';
import 'package:disalive/domain/repositories/auth_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final HttpClientService _httpClient;
  final SecureStorageService _secureStorage;

  AuthRepositoryImpl({
    HttpClientService? httpClient,
    SecureStorageService? secureStorage,
  }) : _httpClient = httpClient ?? sl<HttpClientService>(),
       _secureStorage = secureStorage ?? sl<SecureStorageService>();

  @override
  Future<Either<Failure, AppLogin>> login(
    String email,
    String password,
    String? fcmToken,
  ) async {
    final result = await _httpClient.postFormData<AppLogin>(
      endpoint: 'login.php',
      data: {'email': email, 'password': password, 'fcmToken': fcmToken},
      apiType: ApiType.php,
      requireAuth: false,
      fromJson: (json) {
        return AppLogin(
          requireTotp: json['requireTotp'] ?? false,
          keySession: json['keySession'] ?? '',
        );
      },
    );

    final appLogin = result.fold((failure) => null, (value) => value);
    if (appLogin != null) {
      if (!appLogin.requireTotp && appLogin.keySession.isEmpty) {
        return const Left(ParsingFailure('Ключ сессии отсутствует в ответе'));
      }
      if (appLogin.keySession.isNotEmpty) {
        try {
          await _secureStorage.saveKeySession(appLogin.keySession);
        } catch (_) {
          return const Left(CacheFailure('Не удалось сохранить сессию'));
        }
      }
    }

    return result;
  }

  @override
  Future<Either<Failure, bool>> checkAuth() async {
    final isAuthenticated = await _secureStorage.isAuthenticated();
    return Right(isAuthenticated);
  }

  @override
  Future<Either<Failure, AppLogin>> verifyTotp(
    String email,
    String password,
    String code,
    String? fcmToken,
  ) async {
    final result = await _httpClient.postFormData<AppLogin>(
      endpoint: 'totp/verify.php',
      data: {
        'email': email,
        'password': password,
        'code': code,
        'fcmToken': fcmToken,
      },
      apiType: ApiType.v1,
      requireAuth: false,
      fromJson: (json) {
        return AppLogin(
          requireTotp: json['requireTotp'] ?? false,
          keySession: json['keySession'] ?? '',
        );
      },
    );

    final appLogin = result.fold((failure) => null, (value) => value);
    if (appLogin != null) {
      if (appLogin.keySession.isEmpty) {
        return const Left(ParsingFailure('Ключ сессии отсутствует в ответе'));
      }
      try {
        await _secureStorage.saveKeySession(appLogin.keySession);
      } catch (_) {
        return const Left(CacheFailure('Не удалось сохранить сессию'));
      }
    }

    return result;
  }
}

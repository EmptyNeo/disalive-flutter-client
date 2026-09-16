import 'dart:ui';

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';

class UserRepositoryImpl implements UserRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  final SecureStorageService _secureStorage = sl<SecureStorageService>();

  UserModel? _currentUser;

  @override
  Future<Either<Failure, UserModel>> get(
    String userType,
    String? username, {
    VoidCallback? onUnauthorized,
  }) async {
    final result = await _httpClient.postFormData<UserModel>(
      endpoint: 'users/get.php',
      data: {'type': userType, 'username': ?username},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => UserModel.fromMap(json),
      onUnauthorized: () {
        _secureStorage.clearAll();
        // Вызываем переданный колбэк, если он есть
        if (onUnauthorized != null) {
          onUnauthorized();
        }
      },
    );

    return result;
  }

  @override
  Future<Either<Failure, UserModel>> update(UserModel user) async {
    final result = await _httpClient.postFormData<UserModel>(
      endpoint: 'users/update.php',
      data: user.toMap(),
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => UserModel.fromMap(json),
    );

    return result;
  }

  @override
  UserModel? getCurrentUser() {
    return _currentUser;
  }

  @override
  void setCurrentUser(UserModel user) {
    _currentUser = user;
  }

  @override
  void clearCurrentUser() {
    _currentUser = null;
  }
}

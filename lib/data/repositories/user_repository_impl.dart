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
        if (onUnauthorized != null) {
          onUnauthorized();
        }
      },
    );

    return result;
  }

  @override
  Future<Either<Failure, bool>> hasExistingData(
    String? username,
    String? email,
  ) async {
    Map<String, dynamic> map = {};
    if (username != null) map['username'] = username;
    if (email != null) map['email'] = email;
    final result = await _httpClient.get<bool>(
      endpoint: 'users/check/',
      queryParams: map,
      apiType: ApiType.v1,
      requireAuth: false,
      fromJson: (json) => json["has"] == true,
    );

    return result;
  }

  @override
  Future<Either<Failure, bool>> create(
    String email,
    String? displayName,
    String? username,
    String? password,
    String inputCode,
  ) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'users/create.php',
      data: {
        'email': email,
        'displayName': displayName,
        'username': username,
        'password': password,
        'inputCode': inputCode,
      },
      apiType: ApiType.v1,
      requireAuth: false,
      fromJson: (json) => json['success'] == true,
    );

    return result;
  }

  @override
  Future<Either<Failure, UserModel>> update(UserModel user) async {
    final result = await _httpClient.postMultipart<UserModel>(
      endpoint: 'users/update.php',
      data: user.toMap(),
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => UserModel.fromMap(json),
      files: user.toMapFiles(),
    );

    return result;
  }

  @override
  Future<Either<Failure, bool>> resetPassword(
    String email,
    String inputCode,
    String newPassword,
    String verifyPassword,
  ) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'users/password/',
      data: {
        "email": email,
        "inputCode": inputCode,
        "newPassword": newPassword,
        "verifyPassword": verifyPassword,
      },
      apiType: ApiType.v1,
      requireAuth: false,
      fromJson: (json) => json["success"] == true,
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

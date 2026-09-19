import 'dart:ui';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/user.dart';

abstract class UserRepository {
  Future<Either<Failure, UserModel>> get(
    String userType,
    String? username, {
    VoidCallback? onUnauthorized,
  });

  Future<Either<Failure, bool>> hasExistingData(
    String? username,
    String? email,
  );

  Future<Either<Failure, bool>> create(
    String email,
    String? displayName,
    String? username,
    String? password,
    String inputCode,
  );

  Future<Either<Failure, UserModel>> update(UserModel user);

  Future<Either<Failure, bool>> resetPassword(
    String email,
    String inputCode,
    String newPassword,
    String verifyPassword,
  );

  UserModel? getCurrentUser();

  void setCurrentUser(UserModel user);

  void clearCurrentUser();
}

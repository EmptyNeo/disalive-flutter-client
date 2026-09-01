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

  UserModel? getCurrentUser();

  void setCurrentUser(UserModel user);

  void clearCurrentUser();
}

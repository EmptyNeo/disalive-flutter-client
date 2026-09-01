import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/app_login.dart';

abstract class AuthRepository {
  Future<Either<Failure, AppLogin>> login(String email, String password);

  Future<Either<Failure, bool>> checkAuth();
}

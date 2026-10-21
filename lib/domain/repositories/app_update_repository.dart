import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/app_update.dart';

abstract class AppUpdateRepository {
  Future<Either<Failure, AppUpdate>> checkAndroid(String currentVersion);
}

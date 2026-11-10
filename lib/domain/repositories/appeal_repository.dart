import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/moderation_appeal.dart';

abstract interface class AppealRepository {
  Future<Either<Failure, List<AppealTarget>>> getTargets();
  Future<Either<Failure, List<ModerationAppeal>>> getMine();
  Future<Either<Failure, bool>> create(AppealTarget target, String reason);
}

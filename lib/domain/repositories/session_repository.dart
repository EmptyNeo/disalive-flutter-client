import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/session.dart';

abstract class SessionRepository {
  Future<Either<Failure, List<SessionModel>>> get();

  Future<Either<Failure, bool>> delete(String id, String type);

  Future<int?> getCurrentSessionId();
}

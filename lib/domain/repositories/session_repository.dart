import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/action_session_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/session.dart';

abstract class SessionRepository {
  Future<Either<Failure, List<SessionModel>>> get();

  Future<Either<Failure, bool>> delete(int id, ActionSessionType type);

  List<SessionModel> getSessions();

  Future<int?> getCurrentSessionId();
}

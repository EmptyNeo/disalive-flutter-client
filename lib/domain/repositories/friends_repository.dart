import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';

abstract class FriendsRepository {
  Future<Either<Failure, bool>> toggleBlock(int chatId);

  Future<Either<Failure, bool>> delete(int chatId);
}

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/friend_request.dart';

abstract class RequestsRepository {
  Future<Either<Failure, List<FriendRequest>>> get();

  Future<Either<Failure, bool>> send(String username);

  Future<Either<Failure, bool>> cancel(String username);

  Future<Either<Failure, bool>> accept(String username);

  List<FriendRequest> getCached();

  void clear();
}

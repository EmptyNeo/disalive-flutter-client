import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/profile_comment.dart';

abstract class ProfileCommentsRepository {
  Future<Either<Failure, ProfileCommentsPage>> getComments(
    int profileUserId, {
    int limit = 20,
    int offset = 0,
  });

  Future<Either<Failure, Unit>> createComment(
    int profileUserId,
    String content, {
    int? parentCommentId,
  });

  Future<Either<Failure, Unit>> updateComment(int commentId, String content);
  Future<Either<Failure, Unit>> deleteComment(int commentId);
}

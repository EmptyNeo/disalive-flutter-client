import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/profile_comment_like_result.dart';

abstract class ProfileCommentLikesRepository {
  Future<Either<Failure, ProfileCommentLikeResult>> like(int commentId);
  Future<Either<Failure, ProfileCommentLikeResult>> unlike(int commentId);
}

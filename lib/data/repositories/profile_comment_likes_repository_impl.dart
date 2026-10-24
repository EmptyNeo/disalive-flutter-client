import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/profile_comment_like_result.dart';
import 'package:disalive/domain/repositories/profile_comment_likes_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class ProfileCommentLikesRepositoryImpl
    implements ProfileCommentLikesRepository {
  ProfileCommentLikesRepositoryImpl({HttpClientService? httpClient})
    : _httpClient = httpClient ?? sl<HttpClientService>();

  final HttpClientService _httpClient;

  @override
  Future<Either<Failure, ProfileCommentLikeResult>> like(int commentId) =>
      _send('commentLikes/create.php', commentId);

  @override
  Future<Either<Failure, ProfileCommentLikeResult>> unlike(int commentId) =>
      _send('commentLikes/delete.php', commentId);

  Future<Either<Failure, ProfileCommentLikeResult>> _send(
    String endpoint,
    int commentId,
  ) => _httpClient.postFormData<ProfileCommentLikeResult>(
    endpoint: endpoint,
    apiType: ApiType.v1,
    requireAuth: true,
    data: {'commentId': commentId},
    fromJson: (json) => ProfileCommentLikeResult.fromMap(
      Map<String, dynamic>.from(json as Map),
    ),
  );
}

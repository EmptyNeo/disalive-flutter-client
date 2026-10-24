import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/profile_comment.dart';
import 'package:disalive/domain/repositories/profile_comments_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class ProfileCommentsRepositoryImpl implements ProfileCommentsRepository {
  ProfileCommentsRepositoryImpl({HttpClientService? httpClient})
    : _httpClient = httpClient ?? sl<HttpClientService>();

  final HttpClientService _httpClient;

  @override
  Future<Either<Failure, ProfileCommentsPage>> getComments(
    int profileUserId, {
    int limit = 20,
    int offset = 0,
  }) => _httpClient.postFormData<ProfileCommentsPage>(
    endpoint: 'comments/get.php',
    apiType: ApiType.v1,
    requireAuth: true,
    data: {'profileUserId': profileUserId, 'limit': limit, 'offset': offset},
    fromJson: (json) =>
        ProfileCommentsPage.fromMap(Map<String, dynamic>.from(json as Map)),
  );

  @override
  Future<Either<Failure, Unit>> createComment(
    int profileUserId,
    String content, {
    int? parentCommentId,
  }) => _write('comments/create.php', {
    'profileUserId': profileUserId,
    'content': content,
    'parentCommentId': ?parentCommentId,
  });

  @override
  Future<Either<Failure, Unit>> updateComment(int commentId, String content) =>
      _write('comments/update.php', {
        'commentId': commentId,
        'content': content,
      });

  @override
  Future<Either<Failure, Unit>> deleteComment(int commentId) =>
      _write('comments/delete.php', {'commentId': commentId});

  Future<Either<Failure, Unit>> _write(
    String endpoint,
    Map<String, dynamic> data,
  ) => _httpClient.postFormData<Unit>(
    endpoint: endpoint,
    apiType: ApiType.v1,
    requireAuth: true,
    data: data,
    fromJson: (_) => unit,
  );
}

import 'dart:convert';

import 'package:disalive/data/repositories/profile_comment_likes_repository_impl.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _SessionStorage extends SecureStorageService {
  @override
  Future<String?> getKeySession() async => 'session-key';
}

void main() {
  test('like and unlike call their v1 endpoints with commentId', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      final liked = request.url.path.endsWith('/create.php');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'commentId': 42,
            'likesCount': liked ? 3 : 2,
            'isLiked': liked,
          },
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final httpClient = HttpClientService(
      client: client,
      secureStorage: _SessionStorage(),
    );
    addTearDown(httpClient.dispose);
    final repository = ProfileCommentLikesRepositoryImpl(
      httpClient: httpClient,
    );

    final liked = await repository.like(42);
    final unliked = await repository.unlike(42);

    expect(
      liked.getOrElse(() => throw StateError('like failed')).likesCount,
      3,
    );
    expect(
      liked.getOrElse(() => throw StateError('like failed')).isLiked,
      isTrue,
    );
    expect(
      unliked.getOrElse(() => throw StateError('unlike failed')).likesCount,
      2,
    );
    expect(
      unliked.getOrElse(() => throw StateError('unlike failed')).isLiked,
      isFalse,
    );
    expect(requests.map((request) => request.url.path), [
      endsWith('/v1/commentLikes/create.php'),
      endsWith('/v1/commentLikes/delete.php'),
    ]);
    expect(requests.every((request) => request.method == 'POST'), isTrue);
    expect(
      requests.every((request) => request.bodyFields['commentId'] == '42'),
      isTrue,
    );
  });
}

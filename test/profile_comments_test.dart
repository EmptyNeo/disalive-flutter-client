import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/profile_comment.dart';
import 'package:disalive/domain/models/profile_comment_like_result.dart';
import 'package:disalive/domain/repositories/profile_comment_likes_repository.dart';
import 'package:disalive/domain/repositories/profile_comments_repository.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_comments_bloc.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_comment_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements ProfileCommentsRepository {
  final requests = <(int, int, int)>[];
  final pages = <ProfileCommentsPage>[];
  int? createdParentId;
  int? deletedId;

  @override
  Future<Either<Failure, ProfileCommentsPage>> getComments(
    int profileUserId, {
    int limit = 20,
    int offset = 0,
  }) async {
    requests.add((profileUserId, limit, offset));
    return Right(pages.removeAt(0));
  }

  @override
  Future<Either<Failure, Unit>> createComment(
    int profileUserId,
    String content, {
    int? parentCommentId,
  }) async {
    createdParentId = parentCommentId;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteComment(int commentId) async {
    deletedId = commentId;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> updateComment(
    int commentId,
    String content,
  ) async => const Right(unit);
}

class _LikesRepository implements ProfileCommentLikesRepository {
  int? likedId;
  int? unlikedId;

  @override
  Future<Either<Failure, ProfileCommentLikeResult>> like(int commentId) async {
    likedId = commentId;
    return Right(
      ProfileCommentLikeResult(
        commentId: commentId,
        likesCount: 4,
        isLiked: true,
      ),
    );
  }

  @override
  Future<Either<Failure, ProfileCommentLikeResult>> unlike(
    int commentId,
  ) async {
    unlikedId = commentId;
    return Right(
      ProfileCommentLikeResult(
        commentId: commentId,
        likesCount: 3,
        isLiked: false,
      ),
    );
  }
}

void main() {
  test('deleted parent retains nested live reply from API', () {
    final page = ProfileCommentsPage.fromMap({
      'comments': [
        {
          'id': 1,
          'profileUserId': 7,
          'authorUserId': null,
          'content': null,
          'isDeleted': true,
          'replies': [
            {
              'id': 2,
              'profileUserId': 7,
              'authorUserId': 8,
              'parentCommentId': 1,
              'content': 'Ответ',
              'isDeleted': false,
              'replies': [],
            },
          ],
        },
      ],
      'offset': 0,
      'limit': 20,
      'hasMore': false,
    });

    expect(page.comments.single.isDeleted, isTrue);
    expect(page.comments.single.replies.single.content, 'Ответ');
    expect(page.comments.single.replies.single.parentCommentId, 1);
  });

  testWidgets('deleted parent remains visible alongside its reply', (
    tester,
  ) async {
    const parent = ProfileComment(
      id: 1,
      profileUserId: 7,
      isDeleted: true,
      replies: [
        ProfileComment(
          id: 2,
          profileUserId: 7,
          parentCommentId: 1,
          content: 'Ответ',
        ),
      ],
    );
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: ProfileCommentItem(
            comment: parent,
            currentUserId: 8,
            profileUserId: 7,
            onReply: (_) {},
            onEdit: (_) {},
            onDelete: (_) {},
            onLike: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Комментарий удалён'), findsOneWidget);
    expect(find.text('Ответ'), findsOneWidget);
  });

  testWidgets('heart toggles through callback and reflects liked state', (
    tester,
  ) async {
    int? tappedId;
    Widget item(bool liked, {bool busy = false}) => CupertinoApp(
      home: CupertinoPageScaffold(
        child: ProfileCommentItem(
          comment: ProfileComment(
            id: 2,
            profileUserId: 7,
            content: 'Текст',
            likesCount: liked ? 1 : 0,
            isLiked: liked,
          ),
          currentUserId: 8,
          profileUserId: 7,
          onReply: (_) {},
          onEdit: (_) {},
          onDelete: (_) {},
          onLike: (comment) => tappedId = comment.id,
          likingCommentIds: busy ? {2} : const {},
        ),
      ),
    );

    await tester.pumpWidget(item(false));
    await tester.tap(find.byIcon(CupertinoIcons.heart));
    expect(tappedId, 2);
    await tester.pumpWidget(item(true));
    expect(find.byIcon(CupertinoIcons.heart_fill), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    tappedId = null;
    await tester.pumpWidget(item(true, busy: true));
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(tappedId, isNull);
  });

  test('bloc pages roots and refreshes nested tree after deleting', () async {
    final repository = _Repository()
      ..pages.addAll([
        const ProfileCommentsPage(
          comments: [ProfileComment(id: 1, profileUserId: 7)],
          offset: 0,
          limit: 20,
          hasMore: true,
        ),
        const ProfileCommentsPage(
          comments: [ProfileComment(id: 2, profileUserId: 7)],
          offset: 20,
          limit: 20,
          hasMore: false,
        ),
        const ProfileCommentsPage(
          comments: [ProfileComment(id: 2, profileUserId: 7)],
          offset: 0,
          limit: 40,
          hasMore: false,
        ),
      ]);
    final bloc = ProfileCommentsBloc(repository, _LikesRepository());
    bloc.add(const ProfileCommentsLoad(7));
    await bloc.stream.firstWhere(
      (state) => !state.loading && state.comments.isNotEmpty,
    );
    bloc.add(const ProfileCommentsLoadMore());
    await bloc.stream.firstWhere(
      (state) => !state.loadingMore && state.comments.length == 2,
    );
    bloc.add(const ProfileCommentDelete(1));
    await bloc.stream.firstWhere((state) => state.revision == 1);

    expect(repository.deletedId, 1);
    expect(repository.requests, [(7, 20, 0), (7, 20, 20), (7, 40, 0)]);
    expect(bloc.state.comments.map((comment) => comment.id), [2]);
    await bloc.close();
  });

  test(
    'like and unlike update a nested reply without reloading comments',
    () async {
      final repository = _Repository()
        ..pages.add(
          const ProfileCommentsPage(
            comments: [
              ProfileComment(
                id: 1,
                profileUserId: 7,
                replies: [
                  ProfileComment(id: 2, profileUserId: 7, likesCount: 3),
                ],
              ),
            ],
            offset: 0,
            limit: 20,
            hasMore: false,
          ),
        );
      final likes = _LikesRepository();
      final bloc = ProfileCommentsBloc(repository, likes);
      bloc.add(const ProfileCommentsLoad(7));
      await bloc.stream.firstWhere(
        (state) => !state.loading && state.comments.isNotEmpty,
      );

      bloc.add(const ProfileCommentLikeToggle(2));
      await bloc.stream.firstWhere(
        (state) => state.comments.single.replies.single.isLiked,
      );
      expect(bloc.state.comments.single.replies.single.likesCount, 4);
      expect(likes.likedId, 2);

      bloc.add(const ProfileCommentLikeToggle(2));
      await bloc.stream.firstWhere(
        (state) => !state.comments.single.replies.single.isLiked,
      );
      expect(bloc.state.comments.single.replies.single.likesCount, 3);
      expect(likes.unlikedId, 2);
      expect(repository.requests.length, 1);
      await bloc.close();
    },
  );
}

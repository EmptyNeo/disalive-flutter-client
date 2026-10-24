import 'package:disalive/domain/models/user.dart';

class ProfileComment {
  final int id;
  final int profileUserId;
  final int? authorUserId;
  final int? parentCommentId;
  final String? content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int likesCount;
  final bool isLiked;
  final bool isDeleted;
  final UserModel? author;
  final List<ProfileComment> replies;

  const ProfileComment({
    required this.id,
    required this.profileUserId,
    this.authorUserId,
    this.parentCommentId,
    this.content,
    this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
    this.isLiked = false,
    this.isDeleted = false,
    this.author,
    this.replies = const [],
  });

  ProfileComment withLikes({required int likesCount, required bool isLiked}) =>
      ProfileComment(
        id: id,
        profileUserId: profileUserId,
        authorUserId: authorUserId,
        parentCommentId: parentCommentId,
        content: content,
        createdAt: createdAt,
        updatedAt: updatedAt,
        likesCount: likesCount,
        isLiked: isLiked,
        isDeleted: isDeleted,
        author: author,
        replies: replies,
      );

  ProfileComment withReplies(List<ProfileComment> replies) => ProfileComment(
    id: id,
    profileUserId: profileUserId,
    authorUserId: authorUserId,
    parentCommentId: parentCommentId,
    content: content,
    createdAt: createdAt,
    updatedAt: updatedAt,
    likesCount: likesCount,
    isLiked: isLiked,
    isDeleted: isDeleted,
    author: author,
    replies: replies,
  );

  factory ProfileComment.fromMap(Map<String, dynamic> map) {
    int? number(dynamic value) => value is int ? value : int.tryParse('$value');
    bool flag(dynamic value) => value == true || value == 1 || value == '1';
    DateTime? date(dynamic value) => value == null
        ? null
        : DateTime.tryParse(value.toString().replaceFirst(' ', 'T'));
    final authorData = map['author'];
    return ProfileComment(
      id: number(map['id']) ?? 0,
      profileUserId: number(map['profileUserId']) ?? 0,
      authorUserId: number(map['authorUserId']),
      parentCommentId: number(map['parentCommentId']),
      content: map['content'] as String?,
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
      likesCount: number(map['likesCount']) ?? 0,
      isLiked: flag(map['isLiked']),
      isDeleted: flag(map['isDeleted']),
      author: authorData is Map
          ? UserModel.fromMap(Map<String, dynamic>.from(authorData))
          : null,
      replies: (map['replies'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (reply) => ProfileComment.fromMap(Map<String, dynamic>.from(reply)),
          )
          .toList(growable: false),
    );
  }
}

class ProfileCommentsPage {
  final List<ProfileComment> comments;
  final int offset;
  final int limit;
  final bool hasMore;

  const ProfileCommentsPage({
    required this.comments,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });

  factory ProfileCommentsPage.fromMap(Map<String, dynamic> map) {
    return ProfileCommentsPage(
      comments: (map['comments'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (comment) =>
                ProfileComment.fromMap(Map<String, dynamic>.from(comment)),
          )
          .toList(growable: false),
      offset: (map['offset'] as num?)?.toInt() ?? 0,
      limit: (map['limit'] as num?)?.toInt() ?? 20,
      hasMore: map['hasMore'] == true || map['hasMore'] == 1,
    );
  }
}

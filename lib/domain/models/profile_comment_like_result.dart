class ProfileCommentLikeResult {
  const ProfileCommentLikeResult({
    required this.commentId,
    required this.likesCount,
    required this.isLiked,
  });

  final int commentId;
  final int likesCount;
  final bool isLiked;

  factory ProfileCommentLikeResult.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic value) =>
        value is int ? value : int.tryParse('$value') ?? 0;
    return ProfileCommentLikeResult(
      commentId: parseInt(map['commentId']),
      likesCount: parseInt(map['likesCount']),
      isLiked:
          map['isLiked'] == true ||
          map['isLiked'] == 1 ||
          map['isLiked'] == '1',
    );
  }
}

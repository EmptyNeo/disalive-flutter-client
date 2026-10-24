import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/profile_comment.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

class ProfileCommentItem extends StatelessWidget {
  const ProfileCommentItem({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.profileUserId,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onLike,
    this.likingCommentIds = const {},
    this.canReply = true,
    this.depth = 0,
  });

  final ProfileComment comment;
  final int? currentUserId;
  final int profileUserId;
  final ValueChanged<ProfileComment> onReply;
  final ValueChanged<ProfileComment> onEdit;
  final ValueChanged<ProfileComment> onDelete;
  final ValueChanged<ProfileComment> onLike;
  final Set<int> likingCommentIds;
  final bool canReply;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final deleted = comment.isDeleted;
    final own = !deleted && currentUserId == comment.authorUserId;
    final canDelete = !deleted && (own || currentUserId == profileUserId);
    final created = comment.createdAt;
    final time = created == null
        ? ''
        : '${created.day.toString().padLeft(2, '0')}.${created.month.toString().padLeft(2, '0')}.${created.year}';
    return Padding(
      padding: EdgeInsets.only(left: depth == 0 ? 0 : 12, top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.actionGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!deleted)
                    BuildAvatar(
                      wh: 32,
                      size: 16,
                      url: comment.author?.urlAvatar,
                    )
                  else
                    Icon(
                      CupertinoIcons.person_crop_circle,
                      size: 32,
                      color: AppColors.greyple,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deleted
                          ? 'Удалённый комментарий'
                          : comment.author?.getDisplayName ?? 'Пользователь',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.mediumTextStyle.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    time,
                    style: AppText.mediumTextStyle.copyWith(
                      fontSize: 12,
                      color: AppColors.greyple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                deleted ? 'Комментарий удалён' : comment.content ?? '',
                style: AppText.mediumTextStyle.copyWith(
                  color: deleted ? AppColors.greyple : AppColors.white,
                ),
              ),
              if (!deleted) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 24),
                      onPressed: likingCommentIds.contains(comment.id)
                          ? null
                          : () => onLike(comment),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (likingCommentIds.contains(comment.id))
                            const CupertinoActivityIndicator(radius: 8)
                          else
                            Icon(
                              comment.isLiked
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              size: 17,
                              color: comment.isLiked
                                  ? AppColors.errorRed
                                  : AppColors.greyple,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            '${comment.likesCount}',
                            style: AppText.mediumTextStyle.copyWith(
                              fontSize: 12,
                              color: comment.isLiked
                                  ? AppColors.errorRed
                                  : AppColors.greyple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canReply)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 24),
                        onPressed: () => onReply(comment),
                        child: const Text('Ответить'),
                      ),
                    if (own)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 24),
                        onPressed: () => onEdit(comment),
                        child: const Text('Изменить'),
                      ),
                    if (canDelete)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 24),
                        onPressed: () => onDelete(comment),
                        child: Text(
                          'Удалить',
                          style: TextStyle(color: AppColors.errorRed),
                        ),
                      ),
                  ],
                ),
              ],
              for (final reply in comment.replies)
                ProfileCommentItem(
                  key: ValueKey(reply.id),
                  comment: reply,
                  currentUserId: currentUserId,
                  profileUserId: profileUserId,
                  onReply: onReply,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  onLike: onLike,
                  likingCommentIds: likingCommentIds,
                  canReply: canReply,
                  depth: depth + 1,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

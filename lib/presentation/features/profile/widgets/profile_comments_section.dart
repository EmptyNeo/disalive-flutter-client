import 'dart:convert';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/profile_comment.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_comments_bloc.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_comment_item.dart';
import 'package:disalive/presentation/widgets/error_state_view.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileCommentsSection extends StatefulWidget {
  const ProfileCommentsSection({
    super.key,
    required this.profileUserId,
    required this.canComment,
  });
  final int profileUserId;
  final bool canComment;

  @override
  State<ProfileCommentsSection> createState() => _ProfileCommentsSectionState();
}

class _ProfileCommentsSectionState extends State<ProfileCommentsSection> {
  late final ProfileCommentsBloc _bloc;
  final TextEditingController _controller = TextEditingController();
  ProfileComment? _replyTo;
  ProfileComment? _editing;
  int _lastHandledRevision = 0;

  @override
  void initState() {
    super.initState();
    _bloc = sl<ProfileCommentsBloc>()
      ..add(ProfileCommentsLoad(widget.profileUserId));
    _controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant ProfileCommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileUserId != widget.profileUserId) {
      _cancelDraft();
      _bloc.add(ProfileCommentsLoad(widget.profileUserId));
    }
  }

  void _refresh() => setState(() {});

  void _cancelDraft() {
    _replyTo = null;
    _editing = null;
    _controller.clear();
  }

  void _submit() {
    final content = _controller.text.trim();
    if (content.isEmpty || utf8.encode(content).length > 1000) return;
    if (_editing != null) {
      _bloc.add(ProfileCommentUpdate(_editing!.id, content));
    } else {
      _bloc.add(ProfileCommentCreate(content, parentCommentId: _replyTo?.id));
    }
  }

  void _delete(ProfileComment comment) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Удалить комментарий?'),
        content: const Text('Его ответы останутся видимыми.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(dialogContext);
              _bloc.add(ProfileCommentDelete(comment.id));
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = sl<UserRepository>().getCurrentUser()?.id;
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ProfileCommentsBloc, ProfileCommentsState>(
        listenWhen: (previous, current) =>
            previous.actionError != current.actionError ||
            previous.revision != current.revision,
        listener: (context, state) {
          if (state.actionError != null) {
            CustomToast.open(
              context: context,
              icon: CupertinoIcons.exclamationmark_circle,
              color: AppColors.errorRed,
              message: state.actionError!.message,
            );
          } else if (state.revision != _lastHandledRevision) {
            _lastHandledRevision = state.revision;
            setState(_cancelDraft);
          }
        },
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'КОММЕНТАРИИ',
              style: AppText.mediumTextStyle.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.canComment && (_replyTo != null || _editing != null))
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _editing != null
                          ? 'Редактирование'
                          : 'Ответ для ${_replyTo!.author?.getDisplayName ?? 'пользователя'}',
                      style: AppText.mediumTextStyle.copyWith(
                        fontSize: 12,
                        color: AppColors.greyple,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(28, 28),
                    onPressed: () => setState(_cancelDraft),
                    child: const Icon(CupertinoIcons.xmark, size: 16),
                  ),
                ],
              ),
            if (widget.canComment || _editing != null)
              Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      placeholder: 'Написать комментарий',
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.actionGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      style: AppText.mediumTextStyle.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.only(left: 8),
                    onPressed:
                        state.saving ||
                            _controller.text.trim().isEmpty ||
                            utf8.encode(_controller.text.trim()).length > 1000
                        ? null
                        : _submit,
                    child: state.saving
                        ? const CupertinoActivityIndicator()
                        : const Icon(
                            CupertinoIcons.arrow_up_circle_fill,
                            size: 30,
                          ),
                  ),
                ],
              ),
            if (!widget.canComment)
              Text(
                'Комментарии закрыты для вас',
                style: AppText.mediumTextStyle.copyWith(
                  color: AppColors.greyple,
                ),
              ),
            if (widget.canComment &&
                utf8.encode(_controller.text.trim()).length > 1000)
              Text(
                'Максимум 1000 байт',
                style: AppText.mediumTextStyle.copyWith(
                  fontSize: 12,
                  color: AppColors.errorRed,
                ),
              ),
            const SizedBox(height: 12),
            if (state.loading)
              const Center(child: CupertinoActivityIndicator())
            else if (state.error != null)
              ErrorStateView(
                failure: state.error!,
                onRetry: () =>
                    _bloc.add(ProfileCommentsLoad(widget.profileUserId)),
              )
            else if (state.comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Пока нет комментариев',
                  style: AppText.mediumTextStyle.copyWith(
                    color: AppColors.greyple,
                  ),
                ),
              )
            else
              for (final comment in state.comments)
                ProfileCommentItem(
                  key: ValueKey(comment.id),
                  comment: comment,
                  currentUserId: currentUserId,
                  profileUserId: widget.profileUserId,
                  onReply: (item) => setState(() {
                    _editing = null;
                    _replyTo = item;
                    _controller.clear();
                  }),
                  onEdit: (item) => setState(() {
                    _replyTo = null;
                    _editing = item;
                    _controller.text = item.content ?? '';
                  }),
                  onDelete: _delete,
                  onLike: (item) =>
                      _bloc.add(ProfileCommentLikeToggle(item.id)),
                  likingCommentIds: state.likingCommentIds,
                  canReply: widget.canComment,
                ),
            if (state.hasMore)
              CupertinoButton(
                onPressed: state.loadingMore
                    ? null
                    : () => _bloc.add(const ProfileCommentsLoadMore()),
                child: state.loadingMore
                    ? const CupertinoActivityIndicator()
                    : const Text('Показать ещё'),
              ),
          ],
        ),
      ),
    );
  }
}

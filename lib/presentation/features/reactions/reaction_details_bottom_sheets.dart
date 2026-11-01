import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/reaction_message.dart';
import 'package:disalive/domain/models/reaction_summary.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/reactions/bloc/reaction_details_bloc.dart';
import 'package:disalive/presentation/features/reactions/reaction_item.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReactionSummaryBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required Message message,
    required EntityKey entity,
  }) {
    final messageId = message.id;
    if (messageId == null) return Future.value();
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => sl<ReactionDetailsBloc>()
          ..add(
            LoadReactionSummary(
              messageId: messageId,
              entityId: entity.entityId,
              entityType: entity.entityType,
            ),
          ),
        child: _ReactionSummarySheet(message: message, entity: entity),
      ),
    );
  }
}

class _ReactionSummarySheet extends StatelessWidget {
  const _ReactionSummarySheet({required this.message, required this.entity});

  final Message message;
  final EntityKey entity;

  @override
  Widget build(BuildContext context) {
    final messageId = message.id!;
    final ownReactions = message.reactions ?? const <ReactionMessage>[];
    return _ReactionSheetFrame(
      title: 'Реакции на сообщение',
      child: BlocBuilder<ReactionDetailsBloc, ReactionDetailsState>(
        builder: (context, state) {
          if (state is ReactionDetailsLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (state is ReactionDetailsFailure) {
            return _ReactionLoadError(
              message: state.failure.message,
              onRetry: () => context.read<ReactionDetailsBloc>().add(
                LoadReactionSummary(
                  messageId: messageId,
                  entityId: entity.entityId,
                  entityType: entity.entityType,
                ),
              ),
            );
          }
          if (state is! ReactionSummaryLoaded) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (state.items.isEmpty) {
            return const Center(child: Text('Реакций пока нет'));
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 180 &&
                  state.hasMore &&
                  !state.isLoadingMore) {
                context.read<ReactionDetailsBloc>().add(
                  const LoadMoreReactionSummary(),
                );
              }
              return false;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 78)
                    .floor()
                    .clamp(2, 4)
                    .toInt();
                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.35,
                  ),
                  itemCount:
                      state.items.length +
                      (state.hasMore || state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.items.length) {
                      if (state.paginationFailure != null) {
                        return CupertinoButton(
                          onPressed: () => context
                              .read<ReactionDetailsBloc>()
                              .add(const LoadMoreReactionSummary()),
                          child: const Text('Повторить'),
                        );
                      }
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    final summary = state.items[index];
                    final current = ownReactions
                        .cast<ReactionMessage?>()
                        .firstWhere(
                          (reaction) =>
                              reaction?.nameReaction == summary.nameReaction,
                          orElse: () => null,
                        );
                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        ReactionUsersBottomSheet.show(
                          context,
                          messageId: messageId,
                          entity: entity,
                          reaction: summary,
                        );
                      },
                      child: ReactionItem(
                        reaction: ReactionMessage(
                          nameReaction: summary.nameReaction,
                          amount: summary.amount,
                          hasUserReaction: current?.hasReaction ?? false,
                        ),
                        isMine: false,
                        emojiSize: 21,
                        minHeight: 42,
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ReactionUsersBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required int messageId,
    required EntityKey entity,
    required ReactionSummary reaction,
  }) => showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => sl<ReactionDetailsBloc>()
        ..add(
          LoadReactionUsers(
            messageId: messageId,
            entityId: entity.entityId,
            entityType: entity.entityType,
            nameReaction: reaction.nameReaction,
          ),
        ),
      child: _ReactionUsersSheet(
        reaction: reaction,
        messageId: messageId,
        entity: entity,
      ),
    ),
  );
}

class _ReactionUsersSheet extends StatelessWidget {
  const _ReactionUsersSheet({
    required this.reaction,
    required this.messageId,
    required this.entity,
  });

  final ReactionSummary reaction;
  final int messageId;
  final EntityKey entity;

  @override
  Widget build(BuildContext context) => _ReactionSheetFrame(
    title: 'Поставили реакцию',
    subtitle: ReactionItem(
      reaction: ReactionMessage(
        nameReaction: reaction.nameReaction,
        amount: reaction.amount,
      ),
      isMine: false,
      emojiSize: 20,
    ),
    child: BlocBuilder<ReactionDetailsBloc, ReactionDetailsState>(
      builder: (context, state) {
        if (state is ReactionDetailsLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (state is ReactionDetailsFailure) {
          return _ReactionLoadError(
            message: state.failure.message,
            onRetry: () => context.read<ReactionDetailsBloc>().add(
              LoadReactionUsers(
                messageId: messageId,
                entityId: entity.entityId,
                entityType: entity.entityType,
                nameReaction: reaction.nameReaction,
              ),
            ),
          );
        }
        if (state is! ReactionUsersLoaded) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (state.items.isEmpty) {
          return const Center(child: Text('Пользователи не найдены'));
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 180 &&
                state.hasMore &&
                !state.isLoadingMore) {
              context.read<ReactionDetailsBloc>().add(
                const LoadMoreReactionUsers(),
              );
            }
            return false;
          },
          child: ListView.builder(
            itemCount:
                state.items.length +
                (state.hasMore || state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.items.length) {
                if (state.paginationFailure != null) {
                  return CupertinoButton(
                    onPressed: () => context.read<ReactionDetailsBloc>().add(
                      const LoadMoreReactionUsers(),
                    ),
                    child: const Text('Не удалось загрузить. Повторить'),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(14),
                  child: Center(child: CupertinoActivityIndicator()),
                );
              }
              final user = state.items[index];
              return _ReactionUserRow(user: user);
            },
          ),
        );
      },
    ),
  );
}

class _ReactionUserRow extends StatelessWidget {
  const _ReactionUserRow({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        BuildAvatar(url: user.urlAvatar, wh: 42, size: 24, status: user.status),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.getDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.mediumTextStyle.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (user.username != null)
                Text(
                  '@${user.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.lowTextStyle.copyWith(
                    color: AppColors.greyple,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReactionSheetFrame extends StatelessWidget {
  const _ReactionSheetFrame({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final Widget child;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      height: MediaQuery.sizeOf(context).height * 0.62,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      decoration: BoxDecoration(
        color: AppColors.mainGrey,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppText.mediumTextStyle.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[const SizedBox(height: 6), subtitle!],
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

class _ReactionLoadError extends StatelessWidget {
  const _ReactionLoadError({required this.onRetry, required this.message});

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.isEmpty ? 'Не удалось загрузить реакции' : message,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.greyple),
        ),
        CupertinoButton(onPressed: onRetry, child: const Text('Повторить')),
      ],
    ),
  );
}

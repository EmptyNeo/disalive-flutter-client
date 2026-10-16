import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/media_filter_category.dart';
import 'package:disalive/domain/models/media_filter_item.dart';
import 'package:disalive/domain/models/media_stats.dart';
import 'package:disalive/domain/repositories/media_filter_repository.dart';
import 'package:disalive/presentation/features/media_filters/bloc/media_filters_bloc.dart';
import 'package:disalive/presentation/features/media_filters/media_filter_screen.dart';
import 'package:disalive/presentation/features/media_stats/bloc/media_stats_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum MediaStatsCategory { photos, videos, files, audio, links, mutualChats }

class MediaStatsSection extends StatelessWidget {
  const MediaStatsSection({
    super.key,
    required this.chatId,
    this.showMutualChats = false,
    this.onCategoryTap,
    this.onGroupTap,
  });

  final int chatId;
  final bool showMutualChats;
  final ValueChanged<MediaStatsCategory>? onCategoryTap;
  final ValueChanged<MediaFilterMutualGroup>? onGroupTap;

  void _openCategory(BuildContext context, MediaStatsCategory category) {
    onCategoryTap?.call(category);
    final filterCategory = switch (category) {
      MediaStatsCategory.photos => MediaFilterCategory.photos,
      MediaStatsCategory.videos => MediaFilterCategory.videos,
      MediaStatsCategory.files => MediaFilterCategory.files,
      MediaStatsCategory.audio => MediaFilterCategory.audio,
      MediaStatsCategory.links => MediaFilterCategory.links,
      MediaStatsCategory.mutualChats => MediaFilterCategory.mutualChats,
    };
    SwipeToDismissRoute.push(
      context,
      (_) => BlocProvider(
        create: (_) =>
            MediaFiltersBloc(sl<MediaFilterRepository>())
              ..add(LoadMediaFilter(chatId: chatId, category: filterCategory)),
        child: MediaFilterScreen(
          category: filterCategory,
          onGroupTap: onGroupTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaStatsBloc, MediaStatsState>(
      builder: (context, state) {
        if (state.isLoading && state.stats.isEmpty) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (state.error != null && state.stats.isEmpty) {
          return Center(
            child: CupertinoButton(
              onPressed: () => context.read<MediaStatsBloc>().add(
                const LoadMediaStats(force: true),
              ),
              child: const Text('Не удалось загрузить статистику. Повторить'),
            ),
          );
        }

        final stats = state.forChat(chatId) ?? MediaStats(chatId: chatId);
        final items =
            <
              ({
                MediaStatsCategory category,
                IconData icon,
                String title,
                int count,
              })
            >[
              (
                category: MediaStatsCategory.photos,
                icon: CupertinoIcons.photo_fill,
                title: 'Изображения',
                count: stats.photos,
              ),
              (
                category: MediaStatsCategory.videos,
                icon: CupertinoIcons.film,
                title: 'Видео',
                count: stats.videos,
              ),
              (
                category: MediaStatsCategory.files,
                icon: CupertinoIcons.doc_fill,
                title: 'Файлы',
                count: stats.files,
              ),
              (
                category: MediaStatsCategory.audio,
                icon: CupertinoIcons.music_note_2,
                title: 'Аудиофайлы',
                count: stats.audio,
              ),
              (
                category: MediaStatsCategory.links,
                icon: CupertinoIcons.link,
                title: 'Ссылки',
                count: stats.links,
              ),
              if (showMutualChats)
                (
                  category: MediaStatsCategory.mutualChats,
                  icon: CupertinoIcons.person_2,
                  title: 'Общие группы',
                  count: stats.mutualChatsCount,
                ),
            ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'МЕДИА И ФАЙЛЫ',
                style: AppText.lowTextStyle.copyWith(
                  color: AppColors.greyple,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0) const SizedBox(height: 8),
                  _MediaStatTile(
                    icon: items[index].icon,
                    title: items[index].title,
                    count: items[index].count,
                    onTap: () => _openCategory(context, items[index].category),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MediaStatTile extends StatelessWidget {
  const _MediaStatTile({
    required this.icon,
    required this.title,
    required this.count,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.actionGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.iconGrey, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.lowTextStyle.copyWith(color: AppColors.white),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: AppText.mediumTextStyle.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.iconGrey,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

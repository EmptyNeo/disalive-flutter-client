import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/enums/file_type.dart';
import 'package:disalive/domain/enums/media_filter_category.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/domain/models/media_filter_item.dart';
import 'package:disalive/presentation/features/media/media_viewer_screen.dart';
import 'package:disalive/presentation/features/media_filters/bloc/media_filters_bloc.dart';
import 'package:disalive/presentation/features/media_filters/widgets/media_filter_link_item.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/audio_item.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/file_item.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/image_item.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/video_thumbnail_item.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/custom_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MediaFilterScreen extends StatefulWidget {
  const MediaFilterScreen({super.key, required this.category, this.onGroupTap});

  final MediaFilterCategory category;
  final ValueChanged<MediaFilterMutualGroup>? onGroupTap;

  @override
  State<MediaFilterScreen> createState() => _MediaFilterScreenState();
}

class _MediaFilterScreenState extends State<MediaFilterScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 400) {
      context.read<MediaFiltersBloc>().add(const LoadMoreMediaFilter());
    }
  }

  String get _title => switch (widget.category) {
    MediaFilterCategory.photos => 'Изображения',
    MediaFilterCategory.videos => 'Видео',
    MediaFilterCategory.files => 'Файлы',
    MediaFilterCategory.audio => 'Аудиофайлы',
    MediaFilterCategory.links => 'Ссылки',
    MediaFilterCategory.mutualChats => 'Общие группы',
  };

  FileMessage _asFileMessage(MediaFilterFile item) => FileMessage(
    id: item.idFilesMessage,
    messageId: item.idMessage,
    pathFile: Domain.transformUrl(item.pathFile),
    thumbnailUrl: item.thumbnailUrl == null
        ? null
        : Domain.transformUrl(item.thumbnailUrl),
    originalName: item.originalName,
    size: item.size,
    unit: item.unit,
    objectKey: item.objectKey,
    fileType: switch (widget.category) {
      MediaFilterCategory.photos => FileType.image,
      MediaFilterCategory.videos => FileType.video,
      MediaFilterCategory.audio => FileType.audio,
      _ => FileType.file,
    },
  );

  Rect _sourceRect(BuildContext context) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 80,
      height: 80,
    );
  }

  void _openViewer(
    BuildContext tileContext,
    List<MediaFilterFile> files,
    int index,
  ) {
    MediaViewerScreen.openFiles(
      context,
      files: files.map(_asFileMessage).toList(),
      initialIndex: index,
      sourceRect: _sourceRect(tileContext),
    );
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoColors.transparent,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.mainBackground,
            border: Border.all(color: AppColors.divider),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                BlocConsumer<MediaFiltersBloc, MediaFiltersState>(
                  listener: (context, state) {
                    if (!state.isLoading &&
                        !state.isLoadingMore &&
                        state.hasMore &&
                        state.error == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _onScroll();
                      });
                    }
                  },
                  builder: (context, state) => _buildContent(state),
                ),
                const CustomBackButton(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildContent(MediaFiltersState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: CupertinoButton(
          onPressed: () => context.read<MediaFiltersBloc>().add(
            LoadMediaFilter(chatId: state.chatId!, category: widget.category),
          ),
          child: const Text('Не удалось загрузить. Повторить'),
        ),
      );
    }
    final grid =
        widget.category == MediaFilterCategory.photos ||
        widget.category == MediaFilterCategory.videos;
    final files = grid ? state.items.cast<MediaFilterFile>() : null;
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(56, 14, 16, 22),
            child: Text(
              _title,
              style: AppText.highTextStyle.copyWith(fontSize: 20),
            ),
          ),
        ),
        if (state.items.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('Пока ничего нет')),
          )
        else if (grid)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 130,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: files!.length,
              itemBuilder: (context, index) => Builder(
                builder: (tileContext) {
                  final file = files[index];
                  void onTap() => _openViewer(tileContext, files, index);
                  if (widget.category == MediaFilterCategory.photos) {
                    return GestureDetector(
                      onTap: onTap,
                      child: ImageItem(
                        pathImage: Domain.transformUrl(file.pathFile),
                      ),
                    );
                  }
                  return VideoThumbnailItem(
                    videoSource: Domain.transformUrl(file.pathFile),
                    isNetwork: true,
                    thumbnailPath: file.thumbnailUrl == null
                        ? null
                        : Domain.transformUrl(file.thumbnailUrl),
                    borderRadius: 0,
                    onTap: onTap,
                  );
                },
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            sliver: SliverList.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) =>
                  _buildListItem(state.items[index]),
            ),
          ),
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ),
        if (state.error != null && state.items.isNotEmpty)
          SliverToBoxAdapter(
            child: CupertinoButton(
              onPressed: () => context.read<MediaFiltersBloc>().add(
                const LoadMoreMediaFilter(),
              ),
              child: const Text('Не удалось загрузить ещё. Повторить'),
            ),
          ),
      ],
    );
  }

  Widget _buildListItem(MediaFilterItem item) {
    return switch (item) {
      MediaFilterFile file when widget.category == MediaFilterCategory.audio =>
        AudioItem(file: _asFileMessage(file)),
      MediaFilterFile file => FileItem(file: _asFileMessage(file)),
      MediaFilterLink link => MediaFilterLinkItem(link: link),
      MediaFilterMutualGroup group => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: widget.onGroupTap == null
            ? null
            : () => widget.onGroupTap!(group),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.actionGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              BuildAvatar(
                url: group.pathImage,
                wh: 48,
                size: 25,
                isGroup: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: AppText.mediumTextStyle.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      '${group.memberCount} участников',
                      style: AppText.lowTextStyle.copyWith(
                        color: AppColors.greyple,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.iconGrey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    };
  }
}

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/enums/file_type.dart';
import 'package:disalive/domain/enums/media_filter_category.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/domain/models/media_filter_item.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/presentation/features/media/media_viewer_screen.dart';
import 'package:disalive/presentation/features/media_filters/bloc/media_filters_bloc.dart';
import 'package:disalive/presentation/features/media_filters/widgets/media_filter_link_item.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/audio_item.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/file_item.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/image_item.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/video_thumbnail_item.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/custom_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MediaFilterScreen extends StatefulWidget {
  const MediaFilterScreen({
    super.key,
    required this.category,
    this.onGroupTap,
    this.onServerTap,
    this.onMessageTap,
  });

  final MediaFilterCategory category;
  final ValueChanged<MediaFilterMutualGroup>? onGroupTap;
  final ValueChanged<MediaFilterMutualServer>? onServerTap;
  final ValueChanged<int>? onMessageTap;

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
    MediaFilterCategory.mutualServers => 'Общие серверы',
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

  void _showMessageAction(MediaFilterMessageItem item) {
    if (widget.onMessageTap == null) return;
    ActionBottomSheet.show(
      context,
      actions: [
        ActionItem(
          icon: CupertinoIcons.arrowshape_turn_up_right,
          label: 'Перейти к сообщению',
          onTap: () => widget.onMessageTap?.call(item.idMessage),
        ),
      ],
    );
  }

  DateTime? _dateOf(MediaFilterItem item) {
    final raw = switch (item) {
      MediaFilterFile file => file.time,
      MediaFilterLink link => link.time,
      _ => null,
    };
    if (raw == null) return null;
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  static const _months = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];
  static const _shortMonths = [
    'янв.',
    'февр.',
    'мар.',
    'апр.',
    'мая',
    'июн.',
    'июл.',
    'авг.',
    'сент.',
    'окт.',
    'нояб.',
    'дек.',
  ];

  String _monthLabel(DateTime date) =>
      '${_months[date.month - 1]} ${date.year}';
  String _dayLabel(DateTime date) =>
      '${date.day} ${_shortMonths[date.month - 1]}';

  List<Widget> _datedSlivers(
    MediaFiltersState state,
    List<MediaFilterFile>? files,
  ) {
    final groups = <String, List<int>>{};
    for (var index = 0; index < state.items.length; index++) {
      final date = _dateOf(state.items[index]);
      final month = date == null ? '' : _monthLabel(date);
      groups.putIfAbsent(month, () => []).add(index);
    }
    return [
      for (final entry in groups.entries) ...[
        if (entry.key.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Text(
                entry.key,
                style: AppText.mediumTextStyle.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (files != null)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 130,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: entry.value.length,
              itemBuilder: (context, localIndex) => Builder(
                builder: (tileContext) =>
                    _buildGridTile(tileContext, files, entry.value[localIndex]),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            sliver: SliverList.builder(
              itemCount: entry.value.length,
              itemBuilder: (context, localIndex) {
                final item = state.items[entry.value[localIndex]];
                final date = _dateOf(item);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (date != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _dayLabel(date),
                          style: AppText.lowTextStyle.copyWith(
                            color: AppColors.greyple,
                          ),
                        ),
                      ),
                    _buildListItem(item),
                  ],
                );
              },
            ),
          ),
      ],
    ];
  }

  Widget _buildGridTile(
    BuildContext tileContext,
    List<MediaFilterFile> files,
    int index,
  ) {
    final file = files[index];
    void onTap() => _openViewer(tileContext, files, index);
    final date = _dateOf(file);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showMessageAction(file),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.category == MediaFilterCategory.photos)
            GestureDetector(
              onTap: onTap,
              child: ImageItem(pathImage: Domain.transformUrl(file.pathFile)),
            )
          else
            VideoThumbnailItem(
              videoSource: Domain.transformUrl(file.pathFile),
              isNetwork: true,
              thumbnailPath: file.thumbnailUrl == null
                  ? null
                  : Domain.transformUrl(file.thumbnailUrl),
              borderRadius: 0,
              onTap: onTap,
            ),
          if (date != null)
            Positioned(
              left: 3,
              bottom: 3,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    child: Text(
                      _dayLabel(date),
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
        else if (!grid &&
            (widget.category == MediaFilterCategory.mutualChats ||
                widget.category == MediaFilterCategory.mutualServers))
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            sliver: SliverList.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) =>
                  _buildListItem(state.items[index]),
            ),
          ),
        if (state.items.isNotEmpty &&
            widget.category != MediaFilterCategory.mutualChats &&
            widget.category != MediaFilterCategory.mutualServers)
          ..._datedSlivers(state, files),
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
    final child = switch (item) {
      MediaFilterFile file when widget.category == MediaFilterCategory.audio =>
        AudioItem(file: _asFileMessage(file)),
      MediaFilterFile file => FileItem(file: _asFileMessage(file)),
      MediaFilterLink link => MediaFilterLinkItem(link: link),
      MediaFilterMutualGroup group => _buildCommunityItem(
        name: group.name,
        pathImage: group.pathImage,
        memberCount: group.memberCount,
        onTap: widget.onGroupTap == null
            ? null
            : () => widget.onGroupTap!(group),
      ),
      MediaFilterMutualServer server => _buildCommunityItem(
        name: server.name,
        pathImage: server.pathAvatar,
        memberCount: server.memberCount,
        onTap: widget.onServerTap == null
            ? null
            : () => widget.onServerTap!(server),
      ),
    };
    if (item is! MediaFilterMessageItem) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showMessageAction(item),
      child: child,
    );
  }

  Widget _buildCommunityItem({
    required String name,
    required String? pathImage,
    required int memberCount,
    required VoidCallback? onTap,
  }) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.actionGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          BuildAvatar(url: pathImage, wh: 48, size: 25, isGroup: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppText.mediumTextStyle.copyWith(
                    color: AppColors.white,
                  ),
                ),
                Text(
                  '$memberCount участников',
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
  );
}

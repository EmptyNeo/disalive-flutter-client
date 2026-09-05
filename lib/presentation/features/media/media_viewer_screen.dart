// presentation/features/media/media_viewer_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/ui/media_close_mode.dart';
import 'package:disalive/domain/enums/ui/media_step_direction.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/presentation/features/media/bloc/media_viewer_bloc.dart';
import 'package:disalive/presentation/features/media/media_attachment_locator.dart';
import 'package:disalive/presentation/features/media/media_viewer_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MediaViewerScreen extends StatefulWidget {
  const MediaViewerScreen({
    super.key,
    required this.chat,
    required this.initialPosition,
    required this.setCloseMode,
  });

  final Chat chat;
  final MediaPosition initialPosition;
  final void Function(MediaCloseMode mode) setCloseMode;

  static Future<void> open(
    BuildContext context, {
    required Chat chat,
    required MediaPosition initialPosition,
    required Rect sourceRect,
  }) {
    return MediaViewerRoute.open<void>(
      context,
      sourceRect: sourceRect,
      builder: (context, animation, setCloseMode) {
        return BlocProvider(
          create: (context) => MediaViewerBloc(
            messageRepository: sl<MessageRepository>(),
            chatId: chat.id,
          )..add(LoadInitialMedia(chatId: chat.id)),
          child: MediaViewerScreen(
            chat: chat,
            initialPosition: initialPosition,
            setCloseMode: setCloseMode,
          ),
        );
      },
    );
  }

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late final PageController _pageController;
  final List<MediaPosition> _positions = [];
  late int _initialPageIndex;
  bool _isPositionsBuilt = false;

  @override
  void initState() {
    super.initState();

    // 👇 Пытаемся получить сообщения из кэша ЗАРАНЕЕ
    final messages =
        sl<MessageRepository>().getCached(widget.chat.id)?.messages ?? [];

    // 👇 Вычисляем initialPage сразу
    _initialPageIndex = _computeInitialIndex(messages);

    // 👇 Передаём initialPage в конструктор
    _pageController = PageController(initialPage: _initialPageIndex);

    // 👇 Если данные есть в кэше, строим позиции сразу
    if (messages.isNotEmpty) {
      _buildInitialPositions(messages);
    }
  }

  /// Вычисляет количество "более новых" медиа относительно initialPosition
  int _computeInitialIndex(List<Message> messages) {
    if (messages.isEmpty) return 0;

    int count = 0;
    var cursor = widget.initialPosition;
    while (true) {
      final next = MediaAttachmentLocator.step(
        messages,
        cursor,
        MediaStepDirection.newer,
      );
      if (next == null) break;
      count++;
      cursor = next;
    }
    return count;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _buildInitialPositions(List<Message> messages) {
    if (_isPositionsBuilt || messages.isEmpty) return;

    final newerPositions = <MediaPosition>[];
    var cursor = widget.initialPosition;
    while (true) {
      final next = MediaAttachmentLocator.step(
        messages,
        cursor,
        MediaStepDirection.newer,
      );
      if (next == null) break;
      newerPositions.add(next);
      cursor = next;
    }

    final olderPositions = <MediaPosition>[];
    cursor = widget.initialPosition;
    while (true) {
      final next = MediaAttachmentLocator.step(
        messages,
        cursor,
        MediaStepDirection.older,
      );
      if (next == null) break;
      olderPositions.add(next);
      cursor = next;
    }

    _positions.clear();
    _positions.addAll(newerPositions.reversed);
    _positions.add(widget.initialPosition);
    _positions.addAll(olderPositions);

    _isPositionsBuilt = true;

    // 👇 Дополнительная страховка: jumpToPage через addPostFrameCallback,
    // чтобы гарантировать, что PageView уже построен
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(_initialPageIndex);
      }
    });
  }

  bool _addAllAvailableOlderPositions(List<Message> messages) {
    bool addedAny = false;
    while (true) {
      if (_positions.isEmpty) break;

      final lastPos = _positions.last;
      final next = MediaAttachmentLocator.step(
        messages,
        lastPos,
        MediaStepDirection.older,
      );

      if (next == null) break;

      if (_positions.any((p) => p == next)) break;

      _positions.add(next);
      addedAny = true;
    }
    return addedAny;
  }

  void _ensureMoreData(int pageIndex, List<Message> messages) {
    final added = _addAllAvailableOlderPositions(messages);
    if (added && mounted) {
      setState(() {});
    }

    if (pageIndex >= _positions.length - 2) {
      final bloc = context.read<MediaViewerBloc>();
      final state = bloc.state;

      if (state is MediaViewerLoaded &&
          state.hasMoreMessages &&
          !state.isLoadingMore) {
        _loadMoreMessages(messages);
      }
    }
  }

  void _loadMoreMessages(List<Message> messages) {
    if (messages.isEmpty) return;

    final oldestId = messages.last.getId;

    context.read<MediaViewerBloc>().add(LoadMoreMedia(lastMessageId: oldestId));
  }

  void _handleClose() {
    final currentPageIndex = _pageController.page?.round() ?? _initialPageIndex;

    if (currentPageIndex == _initialPageIndex) {
      widget.setCloseMode(MediaCloseMode.toSource);
    } else if (currentPageIndex < _initialPageIndex) {
      widget.setCloseMode(MediaCloseMode.collapseDown);
    } else {
      widget.setCloseMode(MediaCloseMode.collapseUp);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MediaViewerBloc, MediaViewerState>(
      listener: (context, state) {
        if (state is MediaViewerLoaded) {
          if (!_isPositionsBuilt) {
            _buildInitialPositions(state.messages);
            if (mounted) setState(() {});
          } else {
            final page = _pageController.page?.round() ?? _positions.length - 1;
            _ensureMoreData(page, state.messages);
          }
        }
      },
      child: BlocBuilder<MediaViewerBloc, MediaViewerState>(
        builder: (context, state) {
          if (state is MediaViewerError) {
            return CupertinoPageScaffold(
              backgroundColor: CupertinoColors.transparent,
              child: Center(
                child: Text(
                  'Ошибка: ${state.message}',
                  style: const TextStyle(color: CupertinoColors.white),
                ),
              ),
            );
          }

          if (state is! MediaViewerLoaded || !_isPositionsBuilt) {
            return CupertinoPageScaffold(
              backgroundColor: CupertinoColors.transparent,
              child: const Center(
                child: CupertinoActivityIndicator(color: CupertinoColors.white),
              ),
            );
          }

          final messages = state.messages;

          return CupertinoPageScaffold(
            backgroundColor: CupertinoColors.transparent,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _positions.length,
                  onPageChanged: (index) => _ensureMoreData(index, messages),
                  itemBuilder: (context, index) {
                    if (index < 0 || index >= _positions.length) {
                      return const SizedBox.shrink();
                    }

                    final position = _positions[index];

                    final actualMessageIndex = messages.indexWhere(
                      (m) => (m.id ?? m.localGeneratedId) == position.messageId,
                    );

                    if (actualMessageIndex == -1) {
                      return const Center(
                        child: CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        ),
                      );
                    }

                    final attachments =
                        messages[actualMessageIndex].attachments
                            ?.where((a) => a.isImageFile || a.isVideoFile)
                            .toList() ??
                        const [];

                    if (position.attachmentIndex >= attachments.length) {
                      return const SizedBox.shrink();
                    }

                    return GestureDetector(
                      onTap: _handleClose,
                      child: _MediaPage(
                        attachment: attachments[position.attachmentIndex],
                      ),
                    );
                  },
                ),

                if (state.isLoadingMore)
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    left: 0,
                    right: 0,
                    child: const Center(
                      child: CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),

                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 12,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _handleClose,
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: CupertinoColors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MediaPage extends StatelessWidget {
  const _MediaPage({required this.attachment});

  final FileMessage attachment;

  @override
  Widget build(BuildContext context) {
    if (attachment.isVideoFile) {
      return const Center(
        child: Icon(
          CupertinoIcons.play_circle,
          color: CupertinoColors.white,
          size: 64,
        ),
      );
    }

    return Center(
      child: CachedNetworkImage(
        imageUrl: attachment.pathFile ?? '',
        fit: BoxFit.contain,
        cacheKey: attachment.id?.toString(),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) =>
            const CupertinoActivityIndicator(color: CupertinoColors.white),
        errorWidget: (context, url, error) => const Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: CupertinoColors.white,
          size: 40,
        ),
        maxWidthDiskCache: 2000,
        maxHeightDiskCache: 2000,
      ),
    );
  }
}

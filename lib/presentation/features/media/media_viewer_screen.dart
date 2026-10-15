// presentation/features/media/media_viewer_screen.dart
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/ui/media_close_mode.dart';
import 'package:disalive/domain/enums/ui/media_step_direction.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ui/media_position.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/presentation/features/media/bloc/media_viewer_bloc.dart';
import 'package:disalive/presentation/features/media/media_attachment_locator.dart';
import 'package:disalive/presentation/features/media/media_viewer_route.dart';
import 'package:disalive/presentation/features/media/widgets/media_page.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
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
  late int _currentPage;
  bool _isPositionsBuilt = false;

  @override
  void initState() {
    super.initState();

    final messages =
        sl<MessageRepository>().getCached(widget.chat.id)?.messages ?? [];

    _initialPageIndex = _computeInitialIndex(messages);
    _currentPage = _initialPageIndex;
    _pageController = PageController(initialPage: _initialPageIndex);

    if (messages.isNotEmpty) {
      _buildInitialPositions(messages);
    }
  }

  int _computeInitialIndex(List<Message> messages) {
    if (messages.isEmpty) return 0;

    int count = 0;
    var cursor = widget.initialPosition;
    while (true) {
      final next = MediaAttachmentLocator.step(
        messages,
        cursor,
        MediaStepDirection.older,
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
    _positions.addAll(olderPositions.reversed);
    _positions.add(widget.initialPosition);
    _positions.addAll(newerPositions);

    _isPositionsBuilt = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(_initialPageIndex);
      }

      if (mounted) {
        _ensureMoreData(messages, _initialPageIndex);
      }
    });
  }

  /// Добавляет новые позиции в конец (для WebSocket-сообщений)
  bool _addAllAvailableNewerPositions(List<Message> messages) {
    bool addedAny = false;
    while (true) {
      if (_positions.isEmpty) break;

      final lastPos = _positions.last;
      final next = MediaAttachmentLocator.step(
        messages,
        lastPos,
        MediaStepDirection.newer,
      );

      if (next == null) break;
      if (_positions.any((p) => p == next)) break;

      _positions.add(next);
      addedAny = true;
    }
    return addedAny;
  }

  void _ensureMoreData(List<Message> messages, [int? forcedPageIndex]) {
    int pageIndex;

    // Если индекс передан явно, используем его. Иначе пытаемся взять из контроллера.
    if (forcedPageIndex != null) {
      pageIndex = forcedPageIndex;
    } else {
      try {
        pageIndex = _pageController.page?.round() ?? _initialPageIndex;
      } catch (e) {
        // Защита: если PageView ещё не успел прикрепиться к контроллеру,
        // используем изначальный индекс как безопасный фолбэк.
        pageIndex = _initialPageIndex;
      }
    }

    // Близко к началу (старые) — догружаем
    if (pageIndex <= 2) {
      final bloc = context.read<MediaViewerBloc>();
      final state = bloc.state;

      if (state is MediaViewerLoaded &&
          state.hasMoreMessages &&
          !state.isLoadingMore) {
        _loadMoreMessages(messages);
      }
    }

    // Добавляем новые позиции справа (если пришли через WebSocket)
    final added = _addAllAvailableNewerPositions(messages);
    if (added && mounted) {
      setState(() {});
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
      widget.setCloseMode(MediaCloseMode.collapseUp);
    } else {
      widget.setCloseMode(MediaCloseMode.collapseDown);
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
            _insertLoadedOlderMessages(state.messages);

            if (mounted) {
              _ensureMoreData(state.messages);
            }
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
                  onPageChanged: (index) => _ensureMoreData(messages, index),
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

                    final currentMessage = messages[actualMessageIndex];
                    final contentMessage =
                        currentMessage.forwardMessage ?? currentMessage;

                    final attachments =
                        contentMessage.attachments
                            ?.where((a) => a.isImageFile || a.isVideoFile)
                            .toList() ??
                        const [];

                    if (position.attachmentIndex >= attachments.length) {
                      return const SizedBox.shrink();
                    }

                    return MediaPage(
                      key: ValueKey(
                        '${position.messageId}_${position.attachmentIndex}',
                      ),
                      attachment: attachments[position.attachmentIndex],
                      isActive: index == _currentPage,
                      onClose: _handleClose,
                    );
                  },
                ),

                if (state.isLoadingMore)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: const Center(
                      child: CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                        radius: 14,
                      ),
                    ),
                  ),

                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 12,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: GlassIconButton(
                      icon: CupertinoIcons.xmark,
                      onTap: _handleClose,
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

  /// КЛЮЧЕВОЙ МЕТОД: вставляет старые позиции в начало массива
  /// и ПРЫГАЕТ PageController на новую позицию, чтобы пользователь остался на том же медиа
  void _insertLoadedOlderMessages(List<Message> messages) {
    if (_positions.isEmpty) return;

    final oldestPos = _positions.first;

    final newOlderPositions = <MediaPosition>[];
    var cursor = oldestPos;
    while (true) {
      final next = MediaAttachmentLocator.step(
        messages,
        cursor,
        MediaStepDirection.older,
      );
      if (next == null) break;
      if (_positions.any((p) => p == next)) break;
      newOlderPositions.add(next);
      cursor = next;
    }

    if (newOlderPositions.isEmpty) return;

    // 1. Запоминаем текущую физическую позицию пользователя
    final currentPage = _pageController.page?.round() ?? _initialPageIndex;

    // 2. Вставляем в начало (старые слева)
    _positions.insertAll(0, newOlderPositions.reversed);

    // 3. Корректируем индекс исходной страницы (с которой открыли)
    _initialPageIndex += newOlderPositions.length;

    // 4. Новая позиция пользователя = старая + количество вставленных
    final newCurrentPage = currentPage + newOlderPositions.length;

    if (mounted) {
      setState(() {
        _currentPage = newCurrentPage;
      });

      // 5. ПРЫГАЕМ на новую позицию после обновления itemCount
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(newCurrentPage);
        }
      });
    }
  }
}

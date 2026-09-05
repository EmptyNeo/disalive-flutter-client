// presentation/features/media/media_viewer_screen.dart
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/enums/ui/media_close_mode.dart';
import 'package:disalive/domain/enums/ui/media_step_direction.dart';

// ЗАМЕНИ на реальный путь/имя своей модели вложения — ниже используются
// только attachment.type (image/video) и attachment.pathFile.
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/presentation/features/media/media_attachment_locator.dart';
import 'package:disalive/presentation/features/media/media_viewer_route.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Просмотр вложений поверх текущего чата — фото/видео (видео пока
/// заглушка), свайп между вложениями сообщения, а когда они заканчиваются —
/// переход к следующему/предыдущему сообщению с вложением.
///
/// Не хранит собственный кэш сообщений — читает live-состояние того же
/// [MessageBloc], которым уже пользуется MessagesList: новые сообщения (в
/// т.ч. дозагруженные пагинацией отсюда же) видны сразу, без рассинхрона.
///
/// Направление "к более новым" считается уже полностью загруженным на
/// момент открытия (эти вложения уже есть в кэше бота — докачивать нечего),
/// поэтому весь список позиций в эту сторону строится один раз при
/// инициализации. Направление "к более старым" — наоборот, лениво
/// достраивается по мере приближения к краю, с пагинацией через
/// GetMessages(showed: false), когда hasMoreMessages == true.
class MediaViewerScreen extends StatefulWidget {
  const MediaViewerScreen({
    super.key,
    required this.messageBloc,
    required this.chat,
    required this.initialPosition,
    required this.setCloseMode,
  });

  final MessageBloc messageBloc;
  final Chat chat;
  final MediaPosition initialPosition;
  final void Function(MediaCloseMode mode) setCloseMode;

  /// [sourceRect] — глобальные координаты вложения, из которого открываем
  /// (в вызывающем виджете: RenderBox превью → `localToGlobal(Offset.zero)
  /// & box.size`). Сама верстка превью-вложений в сообщении ещё не
  /// готова — эта точка входа рассчитана на неё заранее.
  static Future<void> open(
    BuildContext context, {
    required MessageBloc messageBloc,
    required Chat chat,
    required MediaPosition initialPosition,
    required Rect sourceRect,
  }) {
    return MediaViewerRoute.open<void>(
      context,
      sourceRect: sourceRect,
      builder: (context, animation, setCloseMode) => MediaViewerScreen(
        messageBloc: messageBloc,
        chat: chat,
        initialPosition: initialPosition,
        setCloseMode: setCloseMode,
      ),
    );
  }

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late final PageController _pageController;
  late List<MediaPosition> _positions;
  bool _isRequestingMore = false;

  List<Message> get _messages {
    final cached = sl<MessageRepository>().getCached(widget.chat.id);
    return cached?.messages ?? [];
  }

  bool get _hasMoreMessages {
    final state = widget.messageBloc.state;
    return state is MessageLoaded ? state.hasMoreMessages : false;
  }

  @override
  void initState() {
    super.initState();

    final messages = _messages;

    // Строим "более новые" (newer) — в начало списка
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

    // Строим "более старые" (older) — в конец списка
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

    // Итог: [newer..., initial, older...]
    _positions = [
      ...newerPositions.reversed,
      widget.initialPosition,
      ...olderPositions,
    ];

    _pageController = PageController(
      initialPage: newerPositions.length, // Индекс initialPosition
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _ensureOlderNeighbor(int pageIndex) {
    // Если не близко к концу списка (старые) — не пагинируем
    if (pageIndex < _positions.length - 5) return;

    final messages = _messages;
    if (messages.isEmpty) return;

    // Берем последнюю позицию (самое старое)
    final lastPos = _positions.last;
    final next = MediaAttachmentLocator.step(
      messages,
      lastPos,
      MediaStepDirection.older,
    );

    if (next != null) {
      setState(() => _positions = [..._positions, next]);
    } else if (_hasMoreMessages && !_isRequestingMore) {
      _loadMoreMessages();
    }
  }

  void _loadMoreMessages() {
    print("LOAD MORE MESSAGES");
    final messages = _messages;
    if (messages.isEmpty) return;
    final oldestId = messages.last.id;
    if (oldestId == null) return;

    _isRequestingMore = true;
    widget.messageBloc.add(
      GetMessages(
        chatId: widget.chat.id,
        entityId: widget.chat.id,
        entityType: EntityType.chat,
        lastIdMessage: oldestId,
        // showed: false — просто догружаем историю для листалки, не
        // помечаем сообщения прочитанными.
        showed: false,
        limit: 60,
      ),
    );
  }

  void _handleClose() {
    final pageIndex = _pageController.page?.round() ?? _positions.length - 1;
    final current = _positions[pageIndex];
    final initial = widget.initialPosition;

    if (current.messageIndex == initial.messageIndex) {
      widget.setCloseMode(MediaCloseMode.toSource);
    } else if (current.messageIndex < initial.messageIndex) {
      // Меньший индекс -> сообщение новее -> визуально ниже исходного.
      widget.setCloseMode(MediaCloseMode.collapseDown);
    } else {
      widget.setCloseMode(MediaCloseMode.collapseUp);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MessageBloc, MessageState>(
      bloc: widget.messageBloc,
      listener: (context, state) {
        if (state is MessageLoaded) {
          _isRequestingMore = false;
          final page = _pageController.hasClients
              ? (_pageController.page?.round() ?? _positions.length - 1)
              : _positions.length - 1;
          _ensureOlderNeighbor(page);
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.transparent,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _positions.length,
              onPageChanged: _ensureOlderNeighbor,
              itemBuilder: (context, index) {
                final position = _positions[index];
                final messages = _messages;

                if (position.messageIndex >= messages.length) {
                  return const Center(
                    child: CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    ),
                  );
                }

                final attachments =
                    messages[position.messageIndex].attachments
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
      // Видео — заглушка, как договорились, без плеера.
      return const Center(
        child: Icon(
          CupertinoIcons.play_circle,
          color: CupertinoColors.white,
          size: 64,
        ),
      );
    }

    return Center(
      child: Image.network(
        attachment.pathFile ?? '',
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const CupertinoActivityIndicator(color: CupertinoColors.white);
        },
        errorBuilder: (context, error, stackTrace) => const Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: CupertinoColors.white,
          size: 40,
        ),
      ),
    );
  }
}

import 'dart:async'; // 🎯 Для Timer
import 'dart:io';

import 'package:disalive/app/di/di.dart'; // 🎯 Для sl()
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/models/ui/media_position.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat/screens/forward_message_screen.dart';
import 'package:disalive/presentation/features/chat/widgets/separators/day_separator.dart';
import 'package:disalive/presentation/features/media/media_viewer_screen.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/message/message_item.dart';
import 'package:disalive/presentation/features/message/widgets/new_messages_separator.dart';
import 'package:disalive/presentation/features/message/widgets/swipes/swipe_to_reply_message.dart';
import 'package:disalive/presentation/utils/app_clipboard.dart';
import 'package:disalive/presentation/utils/ui/message_grouper.dart';
import 'package:disalive/presentation/utils/ui/util_date.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/error_state_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Резерв места под хэдер сверху списка сообщений.
const double _kHeaderReserve = 64;

const double _kLoadMoreThreshold = 100;

class MessagesList extends StatefulWidget {
  final MessageBloc messageBloc;
  final ChatBloc chatBloc;
  final Chat chat;
  final int? currentUserId;
  final double inputReserve;
  final int? initialAroundId;

  final Function(Message message) onSendMessage;
  final Function(Message message) onEditMessage;
  final Function(Message message) onDeleteMessage;
  final Function(Message message) onAnswerMessage;
  final VoidCallback? onFocusInput;
  final VoidCallback? onUnfocusInput;

  const MessagesList({
    super.key,
    required this.messageBloc,
    required this.chatBloc,
    required this.chat,
    required this.currentUserId,
    required this.initialAroundId,
    required this.inputReserve,
    required this.onSendMessage,
    required this.onEditMessage,
    required this.onDeleteMessage,
    required this.onAnswerMessage,
    this.onFocusInput,
    this.onUnfocusInput,
  });

  @override
  State<MessagesList> createState() => MessagesListState();
}

class MessagesListState extends State<MessagesList> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToUnread = false;

  Timer? _readDebounceTimer;
  bool _isUpdatingRead = false;
  bool _hasMarkedInitialUnread = false;
  int? _fixedSeparatorId;
  Timer? _timeForNextSetState;

  int? _highlightedMessageId;
  Timer? _highlightTimer;

  // 🎯 ИСПРАВЛЕНИЕ 1: Ключи должны жить в State, а не в виджете!
  final Map<dynamic, GlobalKey> _messageKeys = {};

  Object? _anchorMessageKeyBeforeLoad;

  Object? _keyOf(Message m) => m.id ?? m.localGeneratedId;

  bool _newerBatchPending = false;

  static const double _kBottomThreshold = 200.0;
  bool _isAtBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fixedSeparatorId = widget.initialAroundId;
  }

  @override
  void didUpdateWidget(covariant MessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat.id != widget.chat.id) {
      _fixedSeparatorId = widget.initialAroundId;
      _hasScrolledToUnread = false;
      _messageKeys.clear(); // Очищаем ключи при смене чата
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _readDebounceTimer?.cancel();
    _timeForNextSetState?.cancel();
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final state = widget.messageBloc.state;
    if (state is! MessageLoaded) return;
    if (state.isLoadingMore || state.isLoadingNewer) return;

    final position = _scrollController.position;

    _timeForNextSetState?.cancel();
    _timeForNextSetState = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _isAtBottom = position.pixels <= _kBottomThreshold;
      });
    });

    if (position.pixels >= position.maxScrollExtent - _kLoadMoreThreshold) {
      if (state.hasMoreMessages) {
        _loadMore(state.messages);
      }
    } else if (position.pixels <= _kLoadMoreThreshold) {
      _loadNewer(state.messages);
    }

    _scheduleReadTracking();
  }

  void _scheduleReadTracking() {
    _readDebounceTimer?.cancel();
    _readDebounceTimer = Timer(
      const Duration(milliseconds: 600),
      _handleReadTracking,
    );
  }

  void _handleReadTracking() {
    if (!mounted || !_scrollController.hasClients) return;
    final state = widget.messageBloc.state;
    if (state is! MessageLoaded) return;

    final messages = state.messages;
    if (messages.isEmpty) return;

    final currentReadId = widget.chat.member?.lastIdReadMessage ?? 0;
    int? targetReadId = _getLowestVisibleMessageId(messages, context);

    if (targetReadId == null) {
      if (widget.initialAroundId != null && !_hasMarkedInitialUnread) {
        targetReadId = messages.first.id;
      } else if (_scrollController.position.pixels < 100) {
        targetReadId = messages.first.id;
      } else {
        return;
      }
    }

    if (targetReadId != null && targetReadId > currentReadId) {
      _updateServerReadStatus(targetReadId);
      if (widget.initialAroundId != null) {
        _hasMarkedInitialUnread = true;
      }
    }
  }

  int? _getLowestVisibleMessageId(
    List<Message> messages,
    BuildContext context,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final limit = messages.length < 15 ? messages.length : 15;

    for (int i = 0; i < limit; i++) {
      final msg = messages[i];
      final msgId = msg.id ?? msg.localGeneratedId;
      // 🎯 ИСПОЛЬЗУЕМ _messageKeys
      final key = _messageKeys[msgId];

      if (key != null) {
        final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final offset = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          if (offset.dy < screenHeight && (offset.dy + size.height) > 0) {
            return msg.id;
          }
        }
      }
    }
    return null;
  }

  void _updateServerReadStatus(int newReadId) async {
    if (_isUpdatingRead || !mounted) return;
    _isUpdatingRead = true;

    try {
      final entityKey = EntityKey(
        entityId: widget.chat.id,
        entityType: EntityType.chat,
      );

      await sl<MembersRepository>().update(
        entityId: entityKey.entityId,
        entityType: entityKey.entityType,
        lastIdReadMessage: newReadId,
        chatId: widget.chat.id,
      );
    } catch (e) {
      debugPrint('Ошибка обновления lastIdReadMessage: $e');
    } finally {
      if (mounted) {
        _isUpdatingRead = false;
      }
    }
  }

  void _loadNewer(List<Message> currentMessages) {
    final newestId = currentMessages.first.id;
    if (newestId == null || newestId <= 0) return;

    final chatLastId = widget.chat.idLastMessage ?? 0;
    if (newestId >= chatLastId) return;

    // 🎯 ЗАПОМИНАЕМ ЯКОРЬ: берем сообщение, которое сейчас первое в списке (оно над спиннером)
    // или то, к которому мы пытаемся перейти
    _anchorMessageKeyBeforeLoad = _keyOf(currentMessages.first);

    _newerBatchPending = true; // Блокируем повторные вызовы
    widget.messageBloc.add(
      GetMessages(
        chatId: widget.chat.id,
        entityId: widget.chat.id,
        entityType: EntityType.chat,
        lastIdMessage: 0,
        newerThanId: newestId,
        limit: 25,
      ),
    );
  }

  void scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(0.0);
    }
  }

  void _loadMore(List<Message> currentMessages) {
    final oldestId = currentMessages.last.id;
    if (oldestId == null || oldestId <= 0) return;

    widget.messageBloc.add(
      GetMessages(
        chatId: widget.chat.id,
        entityId: widget.chat.id,
        entityType: EntityType.chat,
        lastIdMessage: oldestId,
        limit: 25,
      ),
    );
  }

  void _cleanupDeadKeys() {
    // Оставляем в Map только те ключи, чей контекст всё ещё жив и привязан к дереву
    _messageKeys.removeWhere((key, globalKey) {
      return globalKey.currentContext == null;
    });
  }

  Future<bool> _revealMessage(int messageId) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      if (!mounted || !_scrollController.hasClients) return false;

      // 🎯 ПРОВЕРЯЕМ, ЖИВ ЛИ КОНТЕКСТ
      final ctx = _messageKeys[messageId]?.currentContext;
      if (ctx != null) {
        // Элемент построен и жив, скроллим к нему
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.5, // Центрируем
        );
        return true;
      }

      // Если контекста нет, значит элемент не отрисован.
      // Принудительно прыгаем к его предполагаемой позиции, чтобы заставить ListView его построить.
      final state = widget.messageBloc.state;
      if (state is! MessageLoaded || state.messages.isEmpty) return false;

      final index = state.messages.indexWhere((m) => m.id == messageId);
      if (index == -1) return false; // Сообщение исчезло из стейта

      final pos = _scrollController.position;

      // 🎯 ИСПРАВЛЕННАЯ ФОРМУЛА для reverse: true:
      // Индекс 0 (самое новое) находится внизу (offset близок к 0).
      // Чем больше индекс, тем выше сообщение (offset растет).
      final avgExtent =
          (pos.maxScrollExtent - pos.minScrollExtent + pos.viewportDimension) /
          state.messages.length;

      final targetOffset = (index * avgExtent).clamp(
        pos.minScrollExtent,
        pos.maxScrollExtent,
      );

      _scrollController.jumpTo(targetOffset);

      // Ждем, пока Flutter отрисует кадр и создаст RenderBox
      await WidgetsBinding.instance.endOfFrame;

      // 🎯 ВАЖНО: После прыжка снова чистим мертвые ключи
      _cleanupDeadKeys();
    }
    return false;
  }

  Future<void> _navigateToMessage(
    int? targetMessageId, {
    bool highlight = false,
  }) async {
    if (targetMessageId == null) return;

    final state = widget.messageBloc.state;
    if (state is! MessageLoaded) return;

    // 🎯 ШАГ 1: Очищаем мертвые ключи перед проверкой
    _cleanupDeadKeys();

    final isAlreadyLoaded = state.messages.any((m) => m.id == targetMessageId);
    final hasValidContext =
        _messageKeys[targetMessageId]?.currentContext != null;

    // 🎯 ШАГ 2: Если сообщения нет в стейте ИЛИ его ключ мертв (не отрисован), делаем запрос
    if (!isAlreadyLoaded || !hasValidContext) {
      widget.messageBloc.add(
        GetMessages(
          chatId: widget.chat.id,
          entityId: widget.chat.id,
          entityType: EntityType.chat,
          lastIdMessage: 0,
          aroundId: targetMessageId,
          // Используем aroundId, чтобы получить окно вокруг сообщения
          limit: 25,
        ),
      );

      final newState = await widget.messageBloc.stream
          .firstWhere((s) => s is MessageLoaded || s is MessageFailure)
          .timeout(const Duration(seconds: 10), onTimeout: () => state);

      if (newState is MessageFailure || newState == state) {
        debugPrint("❌ Не удалось загрузить сообщение $targetMessageId");
        return;
      }

      final loadedState = newState as MessageLoaded;
      if (!loadedState.messages.any((m) => m.id == targetMessageId)) {
        debugPrint("❌ Сообщение $targetMessageId не найдено в ответе сервера");
        return;
      }
    }

    // 🎯 ШАГ 3: Даем Flutter время на перестройку дерева виджетов
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame; // Двойной фрейм для надежности

    // 🎯 ШАГ 4: Снова чистим ключи, так как после перестройки могли появиться новые/старые
    _cleanupDeadKeys();

    final found = await _revealMessage(targetMessageId);

    if (found && highlight && mounted) {
      setState(() => _highlightedMessageId = targetMessageId);
      _startHighlightTimer();
    } else if (!found && mounted) {
      debugPrint("⚠️ Не удалось доскроллить к сообщению $targetMessageId");
    }
  }

  void _startHighlightTimer() {
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _highlightedMessageId = null;
        });
      }
    });
  }

  Future<void> _handleScrollToBottom() async {
    final state = widget.messageBloc.state;
    if (state is! MessageLoaded) return;

    final currentLatestId = state.messages.first.id ?? 0;
    final chatLatestId = widget.chat.idLastMessage ?? 0;

    if (currentLatestId < chatLatestId && chatLatestId > 0) {
      widget.messageBloc.add(
        GetMessages(
          chatId: widget.chat.id,
          entityId: widget.chat.id,
          entityType: EntityType.chat,
          lastIdMessage: 0,
          limit: 25,
        ),
      );

      await widget.messageBloc.stream.firstWhere((newState) {
        if (newState is MessageLoaded) {
          final newLatestId = newState.messages.first.id ?? 0;
          return !newState.isLoadingMore || newLatestId >= chatLatestId;
        }
        return false;
      });
    }

    if (mounted && _scrollController.hasClients) {
      scrollToBottom(animated: true);
    }
  }

  Widget _buildScrollToBottomButton() {
    final state = widget.messageBloc.state;
    if (state is! MessageLoaded) return const SizedBox.shrink();
    if (!_scrollController.hasClients) return const SizedBox.shrink();
    if (state.messages.isEmpty) return const SizedBox.shrink();

    if (_isAtBottom) return const SizedBox.shrink();

    final unreadCount = widget.chat.unreadCount;
    final showBadge = unreadCount > 0;

    return Positioned(
      right: 10,
      bottom: widget.inputReserve + 5,
      child: GestureDetector(
        onTap: _handleScrollToBottom,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const Icon(
                CupertinoIcons.chevron_down,
                color: CupertinoColors.white,
                size: 24,
              ),
              if (showBadge)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blurple,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: AppText.lowTextStyle.copyWith(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MessageBloc, MessageState>(
          listenWhen: (previous, current) {
            return previous is MessageLoaded && current is MessageLoaded;
          },
          listener: (context, state) {
            // 🎯 ВОССТАНОВЛЕНИЕ ПОЗИЦИИ ПОСЛЕ ЗАГРУЗКИ НОВЫХ СООБЩЕНИЙ
            if (state is MessageLoaded) {
              if (_newerBatchPending && !state.isLoadingNewer) {
                _newerBatchPending = false;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted ||
                      !_scrollController.hasClients ||
                      _anchorMessageKeyBeforeLoad == null) {
                    return;
                  }

                  final ctx =
                      _messageKeys[_anchorMessageKeyBeforeLoad]?.currentContext;
                  if (ctx != null) {
                    // Заставляем Flutter удержать это сообщение на той же визуальной позиции
                    Scrollable.ensureVisible(
                      ctx,
                      alignment: 1.0,
                      // 1.0 в reverse: true означает "прижать к началу списка" (верх), что компенсирует сдвиг
                      duration: Duration
                          .zero, // Мгновенно, без анимации, чтобы не было "мигания"
                    );
                  }
                  _anchorMessageKeyBeforeLoad = null;
                });
              }
            }

            _scheduleReadTracking();
          },
        ),
      ],
      child: BlocBuilder<MessageBloc, MessageState>(
        bloc: widget.messageBloc,
        builder: (context, state) {
          final reservePadding = EdgeInsets.only(
            top: _kHeaderReserve,
            bottom: widget.inputReserve,
          );

          if (state is MessageLoading) {
            return Padding(
              padding: reservePadding,
              child: const Center(child: CupertinoActivityIndicator()),
            );
          }

          if (state is MessageFailure) {
            return Padding(
              padding: reservePadding,
              child: ErrorStateView(failure: state.error),
            );
          }

          final messages = state is MessageLoaded ? state.messages : [];

          if (messages.isEmpty) {
            return Padding(
              padding: reservePadding,
              child: Center(
                child: Text(
                  'Сообщений пока нет',
                  style: AppText.mediumTextStyle.copyWith(
                    color: AppColors.greyple,
                  ),
                ),
              ),
            );
          }

          // 🎯 ИСПРАВЛЕНИЕ 4: Скролл к разделителю вынесен из itemBuilder
          if (_fixedSeparatorId != null &&
              !_hasScrolledToUnread &&
              state is MessageLoaded &&
              !state.isLoadingMore) {
            // Ищем сообщение, которое должно идти сразу после разделителя
            final targetIndex = messages.indexWhere(
              (m) => m.id != null && m.id! > _fixedSeparatorId!,
            );
            if (targetIndex != -1) {
              _hasScrolledToUnread = true;
              final targetId = messages[targetIndex].id!;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _revealMessage(targetId);
              });
            }
          }

          if (_fixedSeparatorId != null) {
            final currentReadId = widget.chat.member?.lastIdReadMessage ?? 0;
            final chatLastId = widget.chat.idLastMessage ?? 0;

            if (currentReadId >= chatLastId && chatLastId > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _fixedSeparatorId = null;
                  });
                }
              });
            }
          }

          final groupedMessages = MessageGrouper.group(
            messages as List<Message>,
            isGroup: widget.chat.isGroup,
            currentUserId: widget.currentUserId,
          );

          final isLoadingMore = state is MessageLoaded
              ? state.isLoadingMore
              : false;
          final isLoadingNewer = state is MessageLoaded
              ? state.isLoadingNewer
              : false;
          final itemCount = messages.length + (isLoadingMore ? 1 : 0);

          return Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: EdgeInsets.only(
                  top: _kHeaderReserve + 8,
                  bottom: widget.inputReserve + 8,
                ),
                itemCount: itemCount,
                // 🎯 ИСПРАВЛЕНИЕ 5: Возвращаем null вместо -1
                findChildIndexCallback: (Key key) {
                  if (key is! ValueKey<Object>) return null;
                  final id = key.value;
                  final i = groupedMessages.indexWhere((g) {
                    final m = g.message;
                    return (m.id ?? m.localGeneratedId) == id;
                  });
                  return i == -1 ? null : i;
                },
                itemBuilder: (context, index) {
                  if (isLoadingMore && index == messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CupertinoActivityIndicator(radius: 10),
                      ),
                    );
                  }

                  final grouped = groupedMessages[index];
                  final message = grouped.message;
                  final messageId = message.id ?? message.localGeneratedId;
                  final currentMsgId = message.id ?? 0;

                  final olderMessage = index + 1 < groupedMessages.length
                      ? groupedMessages[index + 1].message
                      : null;
                  final olderMsgId = olderMessage?.id ?? 0;

                  final showSeparator =
                      _fixedSeparatorId != null &&
                      currentMsgId > _fixedSeparatorId! &&
                      (olderMsgId <= _fixedSeparatorId! || olderMsgId == 0);

                  final separatorKey = showSeparator ? GlobalKey() : null;

                  final isRead = isMessageReadByAny(
                    message: message,
                    currentUserId: widget.currentUserId ?? 0,
                    members: widget.chat.members,
                  );

                  // 🎯 ИСПОЛЬЗУЕМ _messageKeys
                  final key = _messageKeys.putIfAbsent(
                    messageId,
                    () => GlobalKey(),
                  );

                  final messageWidget = SwipeToReplyMessage(
                    key: ValueKey(messageId),
                    onReply: () => widget.onAnswerMessage(message),
                    child: RepaintBoundary(
                      key: key,
                      child: MessageItem(
                        key: ValueKey(messageId),
                        message: message,
                        isMine:
                            widget.currentUserId != null &&
                            message.userId == widget.currentUserId,
                        isRead: isRead,
                        showSender: widget.chat.isGroup,
                        showAvatar: grouped.showAvatar,
                        showTime: grouped.showTime,
                        tailDirection: grouped.tailDirection,
                        hasMessageAbove: grouped.hasMessageAbove,
                        onLongPress: () => _showMessageActions(message),
                        isLoading: message.hasLoading,
                        hasError: message.hasErrorMessage,
                        isHighlighted: _highlightedMessageId == messageId,
                        onNavigateToMessage: _navigateToMessage,
                        onTapImage: (attachmentIndex) {
                          final renderBox =
                              key.currentContext?.findRenderObject()
                                  as RenderBox?;
                          if (renderBox == null) return;
                          _openMediaViewer(
                            message.getId,
                            attachmentIndex,
                            renderBox.localToGlobal(Offset.zero) &
                                renderBox.size,
                          );
                        },
                      ),
                    ),
                  );

                  final dayLabel = UtilDate.formatDayTime(message.time, true);
                  final olderDayLabel = olderMessage != null
                      ? UtilDate.formatDayTime(olderMessage.time, true)
                      : null;
                  final isFirstOfDay = dayLabel != olderDayLabel;

                  Widget finalWidget = messageWidget;

                  if (showSeparator) {
                    finalWidget = Column(
                      key: ValueKey(messageId),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NewMessagesSeparator(key: separatorKey),
                        messageWidget,
                      ],
                    );
                  } else if (dayLabel != null && isFirstOfDay) {
                    finalWidget = Column(
                      key: ValueKey(messageId),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DaySeparator(label: dayLabel),
                        messageWidget,
                      ],
                    );
                  }

                  return finalWidget;
                },
              ),

              if (isLoadingNewer)
                Positioned(
                  bottom: widget.inputReserve,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: AppColors.transparent,
                    child: const Center(child: CupertinoActivityIndicator()),
                  ),
                ),

              _buildScrollToBottomButton(),
            ],
          );
        },
      ),
    );
  }

  void _showMessageActions(Message message) {
    widget.onUnfocusInput?.call();

    final isMyMessage =
        widget.currentUserId != null && message.userId == widget.currentUserId;

    final actions = <ActionItem>[
      if (message.hasErrorMessage)
        ActionItem(
          icon: CupertinoIcons.arrow_clockwise,
          label: getMessageRepeat(message),
          onTap: () {
            switch (message.hasError ?? ActionType.create) {
              case ActionType.create:
                widget.onSendMessage(message);
                break;
              case ActionType.update:
                widget.onEditMessage(message);
                break;
              case ActionType.delete:
                widget.onDeleteMessage(message);
                break;
              case ActionType.block:
                break;
            }
          },
        ),
      ActionItem(
        icon: CupertinoIcons.arrow_turn_up_left,
        label: 'Ответить',
        onTap: () {
          widget.onAnswerMessage(message);
          widget.onFocusInput?.call();
        },
      ),
      if (message.text?.isNotEmpty == true)
        ActionItem(
          icon: CupertinoIcons.square_fill_on_square_fill,
          label: 'Копировать',
          onTap: () {
            AppClipboard.copyText(context, message.text!);
          },
        ),
      ActionItem(
        icon: CupertinoIcons.arrow_turn_up_right,
        label: 'Переслать',
        onTap: () {
          ForwardMessageScreen.open(
            context,
            widget.chatBloc,
            widget.messageBloc,
            message,
          );
        },
      ),
      if (isMyMessage && message.hasError != ActionType.update)
        ActionItem(
          icon: CupertinoIcons.pencil,
          label: 'Редактировать',
          onTap: () {
            widget.onEditMessage(message);
            widget.onFocusInput?.call();
          },
        ),
      if (isMyMessage && message.hasError != ActionType.delete)
        ActionItem(
          icon: CupertinoIcons.trash_fill,
          label: 'Удалить',
          isDestructive: true,
          onTap: () {
            widget.onDeleteMessage(message);
          },
        ),
    ];

    ActionBottomSheet.show(
      context,
      title: "Сообщение от ${message.user?.displayName}",
      actions: actions,
    );
  }

  String getMessageRepeat(Message message) {
    switch (message.hasError ?? ActionType.create) {
      case ActionType.create:
        return 'Отправить повторно';
      case ActionType.update:
        return 'Обновить повторно';
      case ActionType.delete:
        return 'Удалить повторно';
      case ActionType.block:
        return '';
    }
  }

  void _openMediaViewer(int messageId, int attachmentIndex, Rect sourceRect) {
    final position = MediaPosition(
      messageId: messageId,
      attachmentIndex: attachmentIndex,
    );

    MediaViewerScreen.open(
      context,
      chat: widget.chat,
      initialPosition: position,
      sourceRect: sourceRect,
    );
  }

  bool isMessageReadByAny({
    required Message message,
    required int currentUserId,
    required List<Member>? members,
  }) {
    if (message.userId != currentUserId) return false;

    final otherMembers =
        members?.where((m) => m.fkUser != currentUserId).toList() ?? [];
    if (otherMembers.isEmpty) return true;

    final msgId = message.id ?? 0;

    for (final member in otherMembers) {
      final lastReadId = member.lastIdReadMessage ?? 0;
      if (lastReadId >= msgId) {
        return true;
      }
    }

    return false;
  }
}

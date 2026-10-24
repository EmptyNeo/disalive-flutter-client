import 'dart:async'; // 🎯 Для Timer

import 'package:disalive/app/di/di.dart'; // 🎯 Для sl()
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/history_action.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/reaction_message.dart';
import 'package:disalive/domain/models/sticker_content.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/models/ui/media_position.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/services/determining_context_service.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat/screens/forward_message_screen.dart';
import 'package:disalive/presentation/features/chat/widgets/separators/day_separator.dart';
import 'package:disalive/presentation/features/history_actions/history_action_item.dart';
import 'package:disalive/presentation/features/media/media_viewer_screen.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/message/message_item.dart';
import 'package:disalive/presentation/features/message/widgets/new_messages_separator.dart';
import 'package:disalive/presentation/features/message/widgets/swipes/swipe_to_reply_message.dart';
import 'package:disalive/presentation/features/reactions/bloc/preferred_reactions_bloc.dart';
import 'package:disalive/presentation/features/reactions/reaction_bottom_sheet.dart';
import 'package:disalive/presentation/utils/app_clipboard.dart';
import 'package:disalive/presentation/utils/ui/message_grouper.dart';
import 'package:disalive/presentation/utils/ui/util_date.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/error_state_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const double _kLoadMoreThreshold = 100;

String? _historyActionDayLabel(HistoryAction action) {
  final timestamp = action.startTimestamp;
  if (timestamp != null) {
    final utcDate = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    );
    return UtilDate.formatDayTime(utcDate.toIso8601String(), true);
  }
  return UtilDate.formatDayTime(action.startDate, true);
}

class MessagesList extends StatefulWidget {
  final MessageBloc messageBloc;
  final ChatBloc chatBloc;
  final Chat chat;
  final int? currentUserId;
  final double inputReserve;
  final double headerReserve;
  final int? initialAroundId;
  final int? initialPositionId;

  final Function(Message message) onSendMessage;
  final Function(Message message) onEditMessage;
  final Function(Message message) onDeleteMessage;
  final Function(Message message) onAnswerMessage;
  final bool canReply;
  final Function(StickerContent sticker) onStickerTap;
  final ValueChanged<String>? onInviteMention;
  final ValueChanged<int>? onChannelTap;
  final VoidCallback? onFocusInput;
  final VoidCallback? onUnfocusInput;

  const MessagesList({
    super.key,
    required this.messageBloc,
    required this.chatBloc,
    required this.chat,
    required this.currentUserId,
    required this.initialAroundId,
    this.initialPositionId,
    required this.inputReserve,
    this.headerReserve = 64,
    required this.onSendMessage,
    required this.onEditMessage,
    required this.onDeleteMessage,
    required this.onAnswerMessage,
    this.canReply = true,
    required this.onStickerTap,
    this.onInviteMention,
    this.onChannelTap,
    this.onFocusInput,
    this.onUnfocusInput,
  });

  @override
  State<MessagesList> createState() => MessagesListState();
}

class MessagesListState extends State<MessagesList> {
  MessageState? get _chatState {
    final current = widget.messageBloc.state;
    return current.chatId == widget.chat.id ? current : null;
  }

  EntityKey? _currentEntityKey() {
    return DeterminingContextService.getEntityKey();
  }

  // 🎯 1. НОВАЯ АРХИТЕКТУРА СКРОЛЛА
  late final ScrollController _scrollController = _BottomStartController(
    () => _bottomPadding,
  );

  double get _bottomPadding => widget.inputReserve + 8;

  final Key _centerKey = UniqueKey();
  late final _physics = _StickToBottomPhysics(
    enabled: () => !_newerBatchPending,
  );

  Object? _anchorKey;
  bool _newerBatchPending = false;

  // 🎯 2. Твои существующие переменные
  bool _hasScrolledToUnread = false;
  Timer? _readDebounceTimer;
  bool _isUpdatingRead = false;
  int? _fixedSeparatorId;
  Timer? _separatorUpdateTimer;
  static const _separatorUpdateDelay = Duration(seconds: 2);
  bool _hasUserScrolled = false;
  Timer? _timeForNextSetState;
  int? _highlightedMessageId;
  Timer? _highlightTimer;
  final Map<dynamic, GlobalKey> _messageKeys = {};
  bool _restoredPosition = false;

  static const double _kBottomThreshold = 200.0;

  final ValueNotifier<bool> _isAtBottomNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fixedSeparatorId = widget.initialAroundId;
    _anchorKey = widget.initialPositionId;
    _hasScrolledToUnread = widget.initialPositionId != null;

    _startTimeForNextState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _chatState is MessageLoaded) {
        _scheduleReadTracking();
      }
    });
  }

  @override
  void didUpdateWidget(covariant MessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat.id != widget.chat.id) {
      _separatorUpdateTimer?.cancel();
      _fixedSeparatorId = widget.initialAroundId;
      _hasUserScrolled = false;
      _hasScrolledToUnread = false;
      _messageKeys.clear();
      _anchorKey = null;
      _newerBatchPending = false;
      _anchorKey = widget.initialPositionId;
      _restoredPosition = false;
      _hasScrolledToUnread = widget.initialPositionId != null;
    } else if (oldWidget.initialAroundId != widget.initialAroundId) {
      if (_hasUserScrolled || _fixedSeparatorId == null) {
        _scheduleSeparatorUpdate();
      }
    }
  }

  void _scheduleSeparatorUpdate() {
    _separatorUpdateTimer?.cancel();
    final nextSeparatorId = widget.initialAroundId;
    if (_fixedSeparatorId == nextSeparatorId) return;
    _separatorUpdateTimer = Timer(_separatorUpdateDelay, () {
      if (!mounted || widget.initialAroundId != nextSeparatorId) return;
      setState(() {
        _fixedSeparatorId = nextSeparatorId;
        _hasScrolledToUnread = true;
      });
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null &&
        !_hasUserScrolled) {
      _hasUserScrolled = true;
      _scheduleSeparatorUpdate();
    }
    return false;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _readDebounceTimer?.cancel();
    _separatorUpdateTimer?.cancel();
    _timeForNextSetState?.cancel();
    _highlightTimer?.cancel();
    super.dispose();
  }

  // 🎯 3. ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  double get _distanceFromBottom {
    if (!_scrollController.hasClients) return 0;
    final p = _scrollController.position;
    return p.pixels - p.minScrollExtent;
  }

  Object? _keyOf(Message m) => m.id ?? m.localGeneratedId;

  int _resolveAnchorIndex(List<Message> messages) {
    _anchorKey ??= _keyOf(messages.first);
    final i = messages.indexWhere((m) => _keyOf(m) == _anchorKey);
    if (i != -1) return i;

    // Якорь пропал (удален или заменен) — берем ближайшее более старое
    final a = _anchorKey;
    final j = a is int
        ? messages.indexWhere((m) => m.id != null && m.id! < a)
        : -1;
    final resolved = j == -1 ? 0 : j;
    _anchorKey = _keyOf(messages[resolved]);
    return resolved;
  }

  void _cleanupDeadKeys() {
    _messageKeys.removeWhere(
      (key, globalKey) => globalKey.currentContext == null,
    );
  }

  int? firstVisibleMessageId() {
    if (!_scrollController.hasClients) return null;
    final state = _chatState;
    if (state is! MessageLoaded) return null;
    final viewport = context.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.hasSize) return null;
    final top = viewport.localToGlobal(Offset.zero).dy + widget.headerReserve;
    final bottom =
        viewport.localToGlobal(Offset(0, viewport.size.height)).dy -
        widget.inputReserve;
    int? firstId;
    double firstTop = double.infinity;
    for (final message in state.messages) {
      final id = message.id;
      if (id == null) continue;
      final box =
          _messageKeys[id]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      if (y + box.size.height <= top || y >= bottom) continue;
      if (y < firstTop) {
        firstTop = y;
        firstId = id;
      }
    }
    return firstId;
  }

  void _startTimeForNextState() {
    _timeForNextSetState?.cancel();
    _timeForNextSetState = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _isAtBottomNotifier.value = _distanceFromBottom <= _kBottomThreshold;
    });
  }

  // 🎯 4. ОБНОВЛЕННАЯ ЛОГИКА СКРОЛЛА И ПАГИНАЦИИ
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final state = _chatState;
    if (state is! MessageLoaded) return;
    if (state.isLoadingMore || state.isLoadingNewer) return;

    final pos = _scrollController.position;

    // 🎯 ИСПОЛЬЗУЕМ _distanceFromBottom ВМЕСТО pixels
    _startTimeForNextState();

    if (pos.pixels >= pos.maxScrollExtent - _kLoadMoreThreshold) {
      if (state.hasMoreMessages) _loadMore(state.messages);
    } else if (_distanceFromBottom <= _kLoadMoreThreshold) {
      if (state.hasNewerMessages) {
        _loadNewer(state.messages);
      }
    }

    _scheduleReadTracking();
  }

  void _loadNewer(List<Message> currentMessages) {
    if (_newerBatchPending) return; // Защита от дублей

    final newestId = currentMessages.first.id;
    if (newestId == null || newestId <= 0) return;
    final entity = _currentEntityKey();
    if (entity == null) return;

    _newerBatchPending = true;

    widget.messageBloc.add(
      GetMessages(
        chatId: widget.chat.id,
        entityId: entity.entityId,
        entityType: entity.entityType,
        lastIdMessage: 0,
        newerThanId: newestId,
        limit: 25,
      ),
    );
  }

  void _loadMore(List<Message> currentMessages) {
    final oldestId = currentMessages.last.id;
    if (oldestId == null || oldestId <= 0) return;
    final entity = _currentEntityKey();
    if (entity == null) return;

    widget.messageBloc.add(
      GetMessages(
        chatId: widget.chat.id,
        entityId: entity.entityId,
        entityType: entity.entityType,
        lastIdMessage: oldestId,
        limit: 25,
      ),
    );
  }

  Future<void> scrollToBottom({bool animated = true}) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_scrollController.hasClients) return;

    final target = _scrollController.position.minScrollExtent;
    if (animated) {
      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      }
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void navigateToPublic(int? messageId, {bool highlight = false}) {
    _navigateToMessage(messageId, highlight: highlight);
  }

  Future<void> _navigateToMessage(
    int? targetMessageId, {
    bool highlight = true,
  }) async {
    if (targetMessageId == null) return;
    final state = _chatState;
    if (state is! MessageLoaded) return;

    final isLoaded = state.messages.any((m) => m.id == targetMessageId);

    // 1. Пробуем мгновенный скролл, если сообщение уже построено
    if (isLoaded && await _revealMessage(targetMessageId)) {
      if (highlight && mounted) {
        setState(() => _highlightedMessageId = targetMessageId);
        _startHighlightTimer();
      }
      return; // Успех, выходим
    }

    // 2. Fallback: делаем around-загрузку
    final entity = _currentEntityKey();
    if (entity == null) return;
    widget.messageBloc.add(
      GetMessages(
        chatId: widget.chat.id,
        entityId: entity.entityId,
        entityType: entity.entityType,
        lastIdMessage: 0,
        aroundId: targetMessageId,
        limit: 25,
      ),
    );

    final newState = await widget.messageBloc.stream
        .firstWhere(
          (s) =>
              s.chatId == widget.chat.id &&
              (s is MessageLoaded || s is MessageFailure),
        )
        .timeout(const Duration(seconds: 10));

    if (newState is! MessageLoaded) return;
    if (!newState.messages.any((m) => m.id == targetMessageId)) return;

    // Даем Flutter время на первичную перестройку дерева
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    _cleanupDeadKeys();

    final found = await _revealMessage(targetMessageId);

    if (found && highlight && mounted) {
      setState(() => _highlightedMessageId = targetMessageId);
      _startHighlightTimer();
    }
  }

  Future<bool> _revealMessage(int messageId, {double alignment = 0.5}) async {
    if (!mounted || !_scrollController.hasClients) return false;

    // 1. Быстрая проверка: может, он уже построен и находится в кэше?
    _cleanupDeadKeys();
    var ctx = _messageKeys[messageId]?.currentContext;

    if (ctx != null) {
      // Да, построен! Плавно центрируем его.
      if (!ctx.mounted) return false;
      await Scrollable.ensureVisible(
        ctx,
        alignment: alignment,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return true;
    }

    // 2. Если контекста нет, значит виджет НЕ построен (даже если он в стейте).
    // Нам нужно заставить SliverList его построить.
    final state = _chatState;
    if (state is! MessageLoaded) return false;

    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return false; // Сообщения реально нет в стейте

    final pos = _scrollController.position;
    final anchorIndex = _resolveAnchorIndex(state.messages);

    // Вычисляем примерную высоту одного сообщения.
    // Нам не нужна идеальная точность здесь, нам нужно просто попасть в "зону видимости" SliverList.
    final totalContentHeight = pos.maxScrollExtent - pos.minScrollExtent;
    final avgExtent = totalContentHeight > 0
        ? totalContentHeight / state.messages.length
        : 100.0; // Защита от деления на ноль

    // Вычисляем примерный offset относительно якоря.
    final targetOffset = ((index - anchorIndex) * avgExtent).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );

    // 3. 🎯 МАГИЯ: Мгновенно прыгаем на примерную позицию.
    // Это действие ЗАСТАВЛЯЕТ SliverList немедленно вызвать itemBuilder
    // для этого диапазона и создать GlobalKey для нашего сообщения!
    _scrollController.jumpTo(targetOffset);

    // 4. Ждем ровно один кадр, чтобы виджет успел построиться и привязать контекст.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;

    // 5. Теперь контекст ГАРАНТИРОВАННО не null (мы только что заставили его построиться).
    _cleanupDeadKeys();
    ctx = _messageKeys[messageId]?.currentContext;

    if (ctx != null) {
      // Теперь ensureVisible сработает идеально и плавно доцентрует сообщение
      // с учетом его реальной, а не примерной высоты.
      if (!ctx.mounted) return false;
      await Scrollable.ensureVisible(ctx, alignment: alignment);
      return true;
    }

    return false;
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
    final state = _chatState;
    if (state is! MessageLoaded) return;
    final messages = state.messages;
    if (messages.isEmpty) return;
    if (messages.first.chatId != null &&
        messages.first.chatId != widget.chat.id) {
      return;
    }

    final currentReadId = widget.chat.member?.lastIdReadMessage ?? 0;
    final targetReadId =
        _getLowestVisibleMessageId(messages, context) ??
        (_distanceFromBottom < 100 ? messages.first.id : null);

    if (targetReadId == null) {
      return;
    }

    if (targetReadId > currentReadId) {
      _updateServerReadStatus(targetReadId);
    }
  }

  int? _getLowestVisibleMessageId(
    List<Message> messages,
    BuildContext context,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final msgId = msg.id ?? msg.localGeneratedId;
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
    final entityKey = DeterminingContextService.getEntityKey();
    if (entityKey == null) return;
    _isUpdatingRead = true;
    try {
      final result = await sl<MembersRepository>().update(
        entityId: entityKey.entityId,
        entityType: entityKey.entityType,
        lastIdReadMessage: newReadId,
        chatId: widget.chat.id,
      );
      result.fold(
        (failure) =>
            debugPrint('Ошибка обновления lastIdReadMessage: $failure'),
        (updated) {
          if (!updated) {
            debugPrint(
              'lastIdReadMessage не обновлён для чата ${widget.chat.id}',
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Ошибка обновления lastIdReadMessage: $e');
    } finally {
      if (mounted) _isUpdatingRead = false;
    }
  }

  void _startHighlightTimer() {
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  Future<void> handleScrollToBottom({bool animated = true}) async {
    if (!_hasUserScrolled) {
      _hasUserScrolled = true;
      _scheduleSeparatorUpdate();
    }
    final state = _chatState;
    if (state is! MessageLoaded) return;

    final currentLatestId = state.messages.first.id ?? 0;
    final chatLatestId = widget.chat.idLastMessage ?? 0;

    final hasLastMessage =
        currentLatestId == widget.chat.idLastMessage || currentLatestId == 0;

    if (currentLatestId < chatLatestId && chatLatestId > 0 && !hasLastMessage) {
      final entity = _currentEntityKey();
      if (entity == null) return;
      _newerBatchPending = false;

      widget.messageBloc.add(
        GetMessages(
          chatId: widget.chat.id,
          entityId: entity.entityId,
          entityType: entity.entityType,
          lastIdMessage: 0,
          limit: 25,
        ),
      );

      // Ждём, пока загрузятся самые свежие сообщения
      await widget.messageBloc.stream
          .firstWhere((newState) {
            if (newState.chatId != widget.chat.id) return false;
            if (newState is MessageLoaded) {
              final newLatestId = newState.messages.first.id ?? 0;
              _isAtBottomNotifier.value = true;
              return !newState.isLoadingMore || newLatestId >= chatLatestId;
            }
            return false;
          })
          .timeout(const Duration(seconds: 10), onTimeout: () => state);
    }

    // 🎯 Скроллим к низу. scrollToBottom сам дождётся кадра и использует minScrollExtent
    if (mounted && _scrollController.hasClients) {
      await scrollToBottom(animated: animated);
    }
  }

  // 🎯 ДОБАВЛЯЕМ ПАРАМЕТР isAtBottom
  Widget _buildScrollToBottomButton(bool isAtBottom) {
    // 🎯 ПРОВЕРЯЕМ ПЕРЕДАННЫЙ ПАРАМЕТР
    if (isAtBottom) return const SizedBox.shrink();

    final state = _chatState;
    if (state is! MessageLoaded) return const SizedBox.shrink();
    if (!_scrollController.hasClients) return const SizedBox.shrink();
    if (state.messages.isEmpty) return const SizedBox.shrink();

    final unreadCount = widget.chat.unreadCount;
    final showBadge = unreadCount > 0;

    return Positioned(
      right: 10,
      bottom: widget.inputReserve + 5,
      child: GestureDetector(
        onTap: handleScrollToBottom,
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
              Icon(
                CupertinoIcons.chevron_down,
                color: AppColors.white,
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

  // 🎯 7. BUILD МЕТОД С DUAL SLIVERLIST
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MessageBloc, MessageState>(
          bloc: widget.messageBloc,
          listenWhen: (p, c) =>
              c.chatId == widget.chat.id &&
              (c is MessageLoading || c is MessageLoaded),
          listener: (context, state) {
            if (state is MessageLoading) {
              _anchorKey = _restoredPosition ? null : widget.initialPositionId;
              _newerBatchPending = false;
              return;
            }
            if (state is MessageLoaded &&
                !state.isLoadingNewer &&
                _newerBatchPending) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _newerBatchPending = false,
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _scheduleReadTracking();
              final loaded = _chatState;
              if (loaded is MessageLoaded &&
                  loaded.hasNewerMessages &&
                  _scrollController.hasClients &&
                  _distanceFromBottom <= _kLoadMoreThreshold) {
                _loadNewer(loaded.messages);
              }
            });
          },
        ),
      ],
      child: BlocBuilder<MessageBloc, MessageState>(
        bloc: widget.messageBloc,
        builder: (context, state) {
          final reservePadding = EdgeInsets.only(
            top: widget.headerReserve,
            bottom: widget.inputReserve,
          );

          if (state.chatId != widget.chat.id || state is MessageLoading) {
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
          final actions = state is MessageLoaded ? state.actions : const [];
          if (messages.isEmpty) {
            if (actions.isNotEmpty) {
              final sortedActions = [...actions]
                ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
              return ListView.builder(
                controller: _scrollController,
                physics: _physics,
                reverse: true,
                padding: EdgeInsets.only(
                  bottom: _bottomPadding,
                  top: widget.headerReserve + 8,
                ),
                itemCount: sortedActions.length,
                itemBuilder: (_, index) {
                  final action = sortedActions[index];
                  final dayLabel = _historyActionDayLabel(action);
                  final olderDayLabel = index + 1 < sortedActions.length
                      ? _historyActionDayLabel(sortedActions[index + 1])
                      : null;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dayLabel != null && dayLabel != olderDayLabel)
                        DaySeparator(label: dayLabel),
                      HistoryActionItem(
                        key: ValueKey('history-${action.id}'),
                        action: action,
                      ),
                    ],
                  );
                },
              );
            }
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

          if (widget.initialPositionId != null &&
              !_restoredPosition &&
              state is MessageLoaded &&
              !state.isLoadingMore) {
            _restoredPosition = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
              await _revealMessage(widget.initialPositionId!, alignment: 0.1);
            });
          }

          // 🎯 ИСПРАВЛЕННАЯ ЛОГИКА РАЗДЕЛИТЕЛЯ
          if (_fixedSeparatorId != null &&
              !_hasScrolledToUnread &&
              state is MessageLoaded &&
              !state.isLoadingMore) {
            final targetIndex = messages.lastIndexWhere(
              (m) => m.id != null && m.id! > _fixedSeparatorId!,
            );
            if (targetIndex != -1) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                final success = await _revealMessage(messages[targetIndex].id!);
                if (success && mounted) {
                  setState(() => _hasScrolledToUnread = true);
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
          final anchorIndex = _resolveAnchorIndex(messages);
          final actionsByMessageIndex = <int, List<HistoryAction>>{};
          for (final action in actions) {
            final lastId = action.lastIdMessage ?? 0;
            final index = messages.indexWhere((m) => (m.id ?? 0) <= lastId);
            if (index < 0 && state is MessageLoaded && state.hasMoreMessages) {
              continue;
            }
            (actionsByMessageIndex[index < 0 ? messages.length - 1 : index] ??=
                    [])
                .add(action);
          }
          for (final entries in actionsByMessageIndex.values) {
            entries.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
          }

          // 🎯 Локальная функция для построения элемента (чтобы не дублировать код)
          Widget buildMessage(int index) {
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
                olderMessage != null &&
                olderMsgId <= _fixedSeparatorId!;
            final isRead = isMessageReadByAny(
              message: message,
              currentUserId: widget.currentUserId ?? 0,
              members: widget.chat.members,
            );
            final key = _messageKeys.putIfAbsent(messageId, () => GlobalKey());

            final messageWidget = SwipeToReplyMessage(
              key: ValueKey(messageId),
              enabled: widget.canReply,
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
                  onTap: () => _showMessageActions(message),
                  onLongPress: () => _showMessageActions(message),
                  isLoading: message.hasLoading,
                  hasError: message.hasErrorMessage,
                  isHighlighted: _highlightedMessageId == messageId,
                  onNavigateToMessage: _navigateToMessage,
                  onTapImage: (attachmentIndex) {
                    final renderBox =
                        key.currentContext?.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      _openMediaViewer(
                        message.getId,
                        attachmentIndex,
                        renderBox.localToGlobal(Offset.zero) & renderBox.size,
                      );
                    }
                  },
                  onTapReaction: onToggleReaction,
                  onStickerTap: widget.onStickerTap,
                  onInviteMention: widget.onInviteMention,
                  onChannelTap: widget.onChannelTap,
                ),
              ),
            );

            final dayLabel = UtilDate.formatDayTime(message.time, true);
            final olderActions = actionsByMessageIndex[index + 1];
            final olderDayLabel =
                olderActions != null && olderActions.isNotEmpty
                ? _historyActionDayLabel(olderActions.last) ??
                      UtilDate.formatDayTime(olderMessage?.time, true)
                : UtilDate.formatDayTime(olderMessage?.time, true);
            final isFirstOfDay = dayLabel != olderDayLabel;

            Widget finalWidget = messageWidget;
            if (showSeparator || (dayLabel != null && isFirstOfDay)) {
              finalWidget = Column(
                key: ValueKey(messageId),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dayLabel != null && isFirstOfDay)
                    DaySeparator(label: dayLabel),
                  if (showSeparator) NewMessagesSeparator(),
                  messageWidget,
                ],
              );
            }
            final attachedActions = actionsByMessageIndex[index];
            if (attachedActions == null || attachedActions.isEmpty) {
              return finalWidget;
            }
            var previousDayLabel = dayLabel;
            final actionWidgets = <Widget>[];
            for (final action in attachedActions) {
              final actionDay = _historyActionDayLabel(action);
              if (actionDay != null && actionDay != previousDayLabel) {
                actionWidgets.add(DaySeparator(label: actionDay));
              }
              actionWidgets.add(
                HistoryActionItem(
                  key: ValueKey('history-${action.id}'),
                  action: action,
                ),
              );
              previousDayLabel = actionDay ?? previousDayLabel;
            }
            return Column(
              key: ValueKey(messageId),
              mainAxisSize: MainAxisSize.min,
              children: [finalWidget, ...actionWidgets],
            );
          }

          int? globalIndexOf(Key key) {
            if (key is! ValueKey<Object>) return null;
            final i = groupedMessages.indexWhere(
              (g) => (g.message.id ?? g.message.localGeneratedId) == key.value,
            );
            return i == -1 ? null : i;
          }

          return Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: _physics,
                  reverse: true,
                  center: _centerKey,
                  slivers: [
                    // 1. Слайвер для сообщений НОВЕЕ якоря (растет вниз от якоря, в отрицательную сторону offset)
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: _bottomPadding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, j) => buildMessage(anchorIndex - 1 - j),
                          childCount: anchorIndex,
                          findChildIndexCallback: (key) {
                            final i = globalIndexOf(key);
                            return (i != null && i < anchorIndex)
                                ? anchorIndex - 1 - i
                                : null;
                          },
                        ),
                      ),
                    ),
                    // 2. Слайвер для ЯКОРЯ и сообщений СТАРЕЕ него (начало координат, offset 0)
                    SliverPadding(
                      key: _centerKey,
                      padding: EdgeInsets.only(top: widget.headerReserve + 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, k) {
                            final index = anchorIndex + k;
                            if (index == groupedMessages.length &&
                                isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: CupertinoActivityIndicator(radius: 10),
                                ),
                              );
                            }
                            if (index < groupedMessages.length) {
                              return buildMessage(index);
                            }
                            return const SizedBox.shrink();
                          },
                          childCount:
                              groupedMessages.length -
                              anchorIndex +
                              (isLoadingMore ? 1 : 0),
                          findChildIndexCallback: (key) {
                            final i = globalIndexOf(key);
                            return (i != null && i >= anchorIndex)
                                ? i - anchorIndex
                                : null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
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
              ValueListenableBuilder<bool>(
                valueListenable: _isAtBottomNotifier, // Твой ValueNotifier
                builder: (context, isAtBottom, child) {
                  // Вызываем твой аккуратный метод, передавая ему актуальное значение
                  return _buildScrollToBottomButton(isAtBottom);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReactionSheet(Message message) {
    ReactionBottomSheet.show(
      context,
      onReactionSelected: (emoji) {
        final nameReaction = "[${emoji.categoryName}:${emoji.id}]";

        final chatId = widget.chat.id;
        final entity = _currentEntityKey();
        final entityId = entity?.entityId;
        final entityType = entity?.entityType;
        final messageId = message.id;

        if (entityId == null || entityType == null || messageId == null) {
          return;
        }

        context.read<MessageBloc>().add(
          ToggleReaction(
            chatId: chatId,
            entityId: entityId,
            entityType: entityType,
            messageId: messageId,
            nameReaction: nameReaction,
          ),
        );

        final reactions = message.reactions;
        if (reactions != null &&
            reactions.contains(
              reactions.firstWhere((r) => r.nameReaction == nameReaction),
            )) {
          context.read<PreferredReactionsBloc>().add(
            UpsertPreferredReaction(nameReaction: nameReaction),
          );
        }
      },
      preferredReactions:
          (context.read<PreferredReactionsBloc>().state
              is PreferredReactionsLoaded)
          ? (context.read<PreferredReactionsBloc>().state
                    as PreferredReactionsLoaded)
                .reactions
          : null,
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
        icon: CupertinoIcons.smiley,
        label: "Добавить реакцию",
        onTap: () {
          _showReactionSheet(message);
        },
      ),
      if (widget.canReply)
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
      preferredReactions:
          (context.read<PreferredReactionsBloc>().state
              is PreferredReactionsLoaded)
          ? (context.read<PreferredReactionsBloc>().state
                    as PreferredReactionsLoaded)
                .reactions
                .take(4)
                .toList()
          : null,
      onReactionTap: (prefReaction) {
        final entity = _currentEntityKey();
        final nameReaction = prefReaction.nameReaction;
        if (entity?.entityId != null &&
            entity?.entityType != null &&
            message.id != null &&
            nameReaction != null) {
          context.read<MessageBloc>().add(
            ToggleReaction(
              chatId: widget.chat.id,
              entityId: entity!.entityId,
              entityType: entity.entityType,
              messageId: message.getId,
              nameReaction: nameReaction,
            ),
          );

          final reactions = message.reactions;
          if (reactions != null && reactions.contains(prefReaction)) {
            context.read<PreferredReactionsBloc>().add(
              UpsertPreferredReaction(nameReaction: nameReaction),
            );
          }
        }
      },
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

  void onToggleReaction(Message message, ReactionMessage reaction) {
    final chatId = widget.chat.id;
    final entity = _currentEntityKey();
    final entityId = entity?.entityId;
    final entityType = entity?.entityType;
    final messageId = reaction.messageId;
    final nameReaction = reaction.nameReaction;
    if (entityId == null ||
        entityType == null ||
        messageId == null ||
        nameReaction == null) {
      return;
    }

    widget.messageBloc.add(
      ToggleReaction(
        chatId: chatId,
        entityId: entityId,
        entityType: entityType,
        messageId: messageId,
        nameReaction: nameReaction,
      ),
    );

    final reactions = message.reactions;
    if (reactions != null && reactions.contains(reaction)) {
      context.read<PreferredReactionsBloc>().add(
        UpsertPreferredReaction(nameReaction: nameReaction),
      );
    }
  }
}

class _BottomStartController extends ScrollController {
  _BottomStartController(this._bottomPaddingGetter);

  final double Function() _bottomPaddingGetter;

  @override
  double get initialScrollOffset => -_bottomPaddingGetter();
}

// 🎯 8. ФИЗИКА ПРИЛИПАНИЯ К НИЗУ
class _StickToBottomPhysics extends ScrollPhysics {
  const _StickToBottomPhysics({required this.enabled, super.parent});

  final bool Function() enabled;

  @override
  _StickToBottomPhysics applyTo(ScrollPhysics? ancestor) =>
      _StickToBottomPhysics(enabled: enabled, parent: buildParent(ancestor));

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    final wasAtBottom = oldPosition.pixels - oldPosition.minScrollExtent <= 1.0;
    final minChanged =
        (newPosition.minScrollExtent - oldPosition.minScrollExtent).abs() > 0.5;
    if (enabled() && wasAtBottom && minChanged) {
      return newPosition.minScrollExtent;
    }
    return super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );
  }
}

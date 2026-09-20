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

  final Map<dynamic, GlobalKey> messageKeys = {};

  MessagesList({
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
  String? _anchorMessageId;
  bool _isSchedulingScroll = false;

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
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _readDebounceTimer?.cancel(); // 🎯 Очищаем таймер
    super.dispose();
  }
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final state = widget.messageBloc.state;
    if (state is! MessageLoaded) return;
    if (state.isLoadingMore || state.isLoadingNewer) return;

    final position = _scrollController.position;

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted || !_scrollController.hasClients) return;

      if (position.pixels >= position.maxScrollExtent - _kLoadMoreThreshold) {
        if (state.hasMoreMessages) {
          _loadMore(state.messages);
        }
      } else if (position.pixels <= _kLoadMoreThreshold) {
        _loadNewer(state.messages);
      }

      _scheduleReadTracking();
    });
  }

  // 🎯 Запускаем отслеживание прочтения с дебаунсом
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

    // 1. Пытаемся найти ID самого нижнего видимого сообщения
    int? targetReadId = _getLowestVisibleMessageId(messages, context);

    // 2. Fallback логика
    if (targetReadId == null) {
      // Fallback 1: Первоначальная загрузка с непрочитанными
      if (widget.initialAroundId != null && !_hasMarkedInitialUnread) {
        targetReadId = messages.first.id;
      }
      // Fallback 2: Пользователь находится в самом низу (pixels < 100), и пришло новое сообщение
      else if (_scrollController.position.pixels < 100) {
        targetReadId = messages.first.id;
      } else {
        return; // Нечего обновлять или не можем определить
      }
    }

    // 3. Обновляем статус на сервере, если нашли сообщение новее текущего прочитанного
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

    // Проверяем только первые 15 сообщений.
    // В reverse: true они находятся в самом низу списка. Это O(1) и работает мгновенно.
    final limit = messages.length < 15 ? messages.length : 15;

    for (int i = 0; i < limit; i++) {
      final msg = messages[i];
      final msgId = msg.id ?? msg.localGeneratedId;
      final key = widget.messageKeys[msgId];

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

    _anchorMessageId =
        currentMessages.first.id?.toString() ??
        currentMessages.first.localGeneratedId;

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

  void _scheduleScrollToSeparator(GlobalKey separatorKey) {
    if (_hasScrolledToUnread || _isSchedulingScroll) return;
    _isSchedulingScroll = true;
    _attemptScrollToSeparator(separatorKey, 0);
  }

  void _attemptScrollToSeparator(GlobalKey separatorKey, int attempt) {
    if (!mounted || _hasScrolledToUnread) {
      _isSchedulingScroll = false;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final separatorContext = separatorKey.currentContext;
      if (separatorContext == null || !_scrollController.hasClients) {
        return;
      }

      final separatorBox = separatorContext.findRenderObject() as RenderBox?;
      if (separatorBox == null || !_scrollController.hasClients) {
        if (attempt < 10) {
          _attemptScrollToSeparator(separatorKey, attempt + 1);
        } else {
          _isSchedulingScroll = false;
        }
        return;
      }

      final viewport = RenderAbstractViewport.of(separatorBox);
      final reveal = viewport.getOffsetToReveal(separatorBox, 0.5);

      _scrollController.jumpTo(
        reveal.offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      );

        _hasScrolledToUnread = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MessageBloc, MessageState>(
          listenWhen: (previous, current) {
            // 🎯 Срабатывает ровно в тот момент, когда загрузка новых сообщений ЗАВЕРШИЛАСЬ
            return previous is MessageLoaded &&
                previous.isLoadingNewer == true &&
                current is MessageLoaded &&
                current.isLoadingNewer == false;
          },
          listener: (context, state) {
            // 🎯 1. ВОССТАНОВЛЕНИЕ СКРОЛЛА ПО ЯКОРЮ
            if (_anchorMessageId != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || !_scrollController.hasClients) return;

                // Ищем наш "якорный" виджет в обновленном списке
                final anchorKey = widget.messageKeys[_anchorMessageId];
                if (anchorKey?.currentContext == null) return;

                final renderBox =
                    anchorKey!.currentContext!.findRenderObject() as RenderBox?;
                if (renderBox == null) return;

                final viewport = RenderAbstractViewport.of(renderBox);

                final reveal = viewport.getOffsetToReveal(renderBox, 1.0);

                // Используем jumpTo для мгновенного, бесшовного восстановления (без анимации)
                _scrollController.jumpTo(
                  reveal.offset.clamp(
                    0.0,
                    _scrollController.position.maxScrollExtent,
                  ),
                );

                _anchorMessageId =
                    null; // 🎯 Сбрасываем якорь после успешного восстановления
              });
            }

            // 🎯 2. Запускаем отслеживание прочтения (как было раньше)
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

          // 🎯 РАЗМОРОЗКА РАЗДЕЛИТЕЛЯ
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
          final itemCount =
              messages.length +
              (isLoadingMore ? 1 : 0) +
              (isLoadingNewer ? 1 : 0);

          return ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: EdgeInsets.only(
              top: _kHeaderReserve + 8,
              bottom: widget.inputReserve + 8,
            ),
            itemCount: itemCount,
            findChildIndexCallback: (Key key) {
              if (key is! ValueKey<Object>) return null;
              final id = key.value;
              final index = groupedMessages.indexWhere((g) {
                final m = g.message;
                return (m.id ?? m.localGeneratedId) == id;
              });
              if (index == -1) return null;
              return isLoadingNewer ? index + 1 : index;
            },
            itemBuilder: (context, index) {
              if (isLoadingNewer && index == 0) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CupertinoActivityIndicator(radius: 10)),
                );
              }

              final messageIndex = isLoadingNewer ? index - 1 : index;

              if (isLoadingMore && messageIndex == messages.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CupertinoActivityIndicator(radius: 10)),
                );
              }

              final grouped = groupedMessages[messageIndex];
              final message = grouped.message;
              final messageId = message.id ?? message.localGeneratedId;
              final currentMsgId = message.id ?? 0;

              final olderMessage = messageIndex + 1 < groupedMessages.length
                  ? groupedMessages[messageIndex + 1].message
                  : null;
              final olderMsgId = olderMessage?.id ?? 0;

              // 🎯 Используем _fixedSeparatorId напрямую, без пересчёта
              final showSeparator =
                  _fixedSeparatorId != null &&
                  currentMsgId > _fixedSeparatorId! &&
                  (olderMsgId <= _fixedSeparatorId! || olderMsgId == 0);

              final separatorKey = showSeparator ? GlobalKey() : null;

              // 🎯 Логика автоскролла
              if (showSeparator &&
                  !_hasScrolledToUnread &&
                  !isLoadingMore &&
                  separatorKey != null) {
                _scheduleScrollToSeparator(separatorKey);
              }

              final isRead = isMessageReadByAny(
                message: message,
                currentUserId: widget.currentUserId ?? 0,
                members: widget.chat.members,
              );

              final key = widget.messageKeys.putIfAbsent(
                messageId,
                () => GlobalKey(),
              );

              final messageWidget = SwipeToReplyMessage(
                key: ValueKey(messageId),
                onReply: () {
                  widget.onAnswerMessage(message);
                },
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
                    onTapImage: (attachmentIndex) {
                      final renderBox =
                          key.currentContext?.findRenderObject() as RenderBox?;
                      if (renderBox == null) return;

                      final sourceRect =
                          renderBox.localToGlobal(Offset.zero) & renderBox.size;
                      _openMediaViewer(
                        message.getId,
                        attachmentIndex,
                        sourceRect,
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

      // Ответить
      ActionItem(
        icon: CupertinoIcons.arrow_turn_up_left,
        label: 'Ответить',
        onTap: () {
          widget.onAnswerMessage(message);
          widget.onFocusInput?.call();
        },
      ),

      // Копировать (только если есть текст)
      if (message.text?.isNotEmpty == true)
        ActionItem(
          icon: CupertinoIcons.square_fill_on_square_fill,
          label: 'Копировать',
          onTap: () {
            AppClipboard.copyText(context, message.text!);
          },
        ),

      // Переслать
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

      // Редактировать (только для своих)
      if (isMyMessage && message.hasError != ActionType.update)
        ActionItem(
          icon: CupertinoIcons.pencil,
          label: 'Редактировать',
          onTap: () {
            widget.onEditMessage(message);
            widget.onFocusInput?.call();
          },
        ),

      // Удалить (только для своих)
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

  /// Определяет, прочитано ли сообщение ХОТЯ БЫ ОДНИМ другим участником чата.
  bool isMessageReadByAny({
    required Message message,
    required int currentUserId,
    required List<Member>? members,
  }) {
    // 1. Статус показываем только для своих сообщений
    if (message.userId != currentUserId) return false;

    final otherMembers =
        members?.where((m) => m.fkUser != currentUserId).toList() ?? [];

    // 2. Если других участников нет (например, соло-чат), считаем сообщение "прочитанным"
    // (так как отправитель и получатель — одно лицо, или система доставила его мгновенно)
    if (otherMembers.isEmpty) return true;

    final msgId = message.id ?? 0;

    // 3. Проверяем, прочитал ли ХОТЯ БЫ ОДИН участник
    for (final member in otherMembers) {
      final lastReadId = member.lastIdReadMessage ?? 0;

      // Если чей-то lastIdReadMessage больше или равен ID сообщения, значит, он его видел
      if (lastReadId >= msgId) {
        return true;
      }
    }

    // 4. Если цикл завершился и никто из остальных не дочитал до этого сообщения
    return false;
  }
}

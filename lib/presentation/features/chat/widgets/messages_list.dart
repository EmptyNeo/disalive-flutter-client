import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/models/ui/media_position.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat/screens/forward_message_screen.dart';
import 'package:disalive/presentation/features/chat/widgets/separators/day_separator.dart';
import 'package:disalive/presentation/features/media/media_viewer_screen.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/message/message_item.dart';
import 'package:disalive/presentation/features/message/widgets/swipes/swipe_to_reply_message.dart';
import 'package:disalive/presentation/utils/app_clipboard.dart';
import 'package:disalive/presentation/utils/ui/message_grouper.dart';
import 'package:disalive/presentation/utils/ui/util_date.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';  
import 'package:disalive/presentation/widgets/error_state_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Резерв места под хэдер сверху списка сообщений.
const double _kHeaderReserve = 64;

const double _kLoadMoreThreshold = 200;

class MessagesList extends StatefulWidget {
  final MessageBloc messageBloc;
  final ChatBloc chatBloc;
  final Chat chat;
  final int? currentUserId;
  final double inputReserve;

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final state = widget.messageBloc.state;
    if (state is! MessageLoaded) return;

    if (state.isLoadingMore || !state.hasMoreMessages) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _kLoadMoreThreshold) {
      _loadMore(state.messages);
    }
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ИСПОЛЬЗУЕМ BlocBuilder ВМЕСТО BlocConsumer
    return BlocBuilder<MessageBloc, MessageState>(
      bloc: widget.messageBloc,
      builder: (context, state) {
        final reservePadding = EdgeInsets.only(
          top: _kHeaderReserve,
          bottom: widget.inputReserve,
        );

        // 1. Состояние загрузки
        if (state is MessageLoading) {
          return Padding(
            padding: reservePadding,
            child: const Center(child: CupertinoActivityIndicator()),
          );
        }

        // 2. Состояние ошибки
        if (state is MessageFailure) {
          return Padding(
            padding: reservePadding,
            child: ErrorStateView(failure: state.error),
          );
        }

        // 3. Успешная загрузка (или пустой список)
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

        final groupedMessages = MessageGrouper.group(
          messages as List<Message>,
          isGroup: widget.chat.isGroup,
          currentUserId: widget.currentUserId,
        );

        final isLoadingMore = state is MessageLoaded
            ? state.isLoadingMore
            : false;
        final itemCount = messages.length + (isLoadingMore ? 1 : 0);

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: EdgeInsets.only(
            top: _kHeaderReserve + 8,
            bottom: widget.inputReserve + 8,
          ),
          itemCount: itemCount,
          // Эта функция спасает позицию скролла при добавлении элементов в начало
          findChildIndexCallback: (Key key) {
            if (key is! ValueKey<Object>) return null;
            final id = key.value;
            final index = groupedMessages.indexWhere((g) {
              final m = g.message;
              return (m.id ?? m.localGeneratedId) == id;
            });
            return index == -1 ? null : index;
          },

          // lib/presentation/features/chat/widgets/messages_list.dart
          itemBuilder: (context, index) {
            if (isLoadingMore && index == messages.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CupertinoActivityIndicator(radius: 10)),
              );
            }

            final grouped = groupedMessages[index];
            final message = grouped.message;
            final messageId = message.id ?? message.localGeneratedId;

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

            // Список newest-first, а ListView с reverse: true рисует index 0
            // внизу и увеличивает индекс вверх — значит groupedMessages[index+1]
            // хронологически СТАРШЕ и рисуется НАД текущим сообщением. Поэтому
            // "это сообщение — самое старое в своём дне" проверяем сравнением
            // с лейблом дня следующего (более старого) сообщения: если лейблы
            // разошлись (или более старого сообщения вообще нет — это конец
            // списка), сепаратор для этого дня вставляем НАД текущим слотом.
            final dayLabel = UtilDate.formatDayTime(message.time, true);
            if (dayLabel == null) return messageWidget;

            final olderMessage = index + 1 < groupedMessages.length
                ? groupedMessages[index + 1].message
                : null;
            final olderDayLabel = olderMessage != null
                ? UtilDate.formatDayTime(olderMessage.time, true)
                : null;

            final isFirstOfDay = dayLabel != olderDayLabel;
            if (!isFirstOfDay) return messageWidget;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DaySeparator(label: dayLabel),
                messageWidget,
              ],
            );
          },
        );
      },
    );
  }

  void _showMessageActions(Message message) {
    widget.onUnfocusInput?.call();

    final isMyMessage =
        widget.currentUserId != null && message.userId == widget.currentUserId;

    var messageRepeat = getMessageRepeat(message);

    final actions = <ActionItem>[
      if (message.hasErrorMessage)
        ActionItem(
          icon: CupertinoIcons.arrow_clockwise,
          label: messageRepeat,
          onTap: () => {
            switch (message.hasError ?? ActionType.create) {
              ActionType.create => widget.onSendMessage(message),
              ActionType.update => widget.onEditMessage(message),
              ActionType.delete => widget.onDeleteMessage(message),
              ActionType.block => null,
            },
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

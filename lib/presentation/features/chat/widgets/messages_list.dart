import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/message/message_item.dart';
import 'package:disalive/presentation/utils/message_grouper.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Резерв места под хэдер сверху списка сообщений.
const double _kHeaderReserve = 64;

const double _kLoadMoreThreshold = 200;

class MessagesList extends StatefulWidget {
  final MessageBloc messageBloc;
  final Chat chat;
  final int? currentUserId;
  final double inputReserve;

  final Function(Message message) onSendMessage;
  final Function(Message message) onEditMessage;
  final Function(Message message) onDeleteMessage;

  const MessagesList({
    super.key,
    required this.messageBloc,
    required this.chat,
    required this.currentUserId,
    required this.inputReserve,
    required this.onSendMessage,
    required this.onEditMessage,
    required this.onDeleteMessage,
  });

  @override
  State<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];

  bool _isLoadingMore = false;
  bool _hasMore = true;

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
    if (_isLoadingMore || !_hasMore || _messages.isEmpty) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _kLoadMoreThreshold) {
      _loadMore();
    }
  }

  void _loadMore() {
    // Список с reverse: true, поэтому самый старый элемент — последний
    final oldestId = _messages.last.id;
    if (oldestId == null || oldestId <= 0) {
      _hasMore = false;
      return;
    }

    setState(() => _isLoadingMore = true);
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
    return BlocConsumer<MessageBloc, MessageState>(
      bloc: widget.messageBloc,
      listener: (context, state) {
        if (state is MessageLoaded) {
          setState(() {
            _messages = state.messages;
            _isLoadingMore = state.isLoadingMore;
            _hasMore = state.hasMoreMessages;
          });
        } else if (state is MessageFailure) {
          setState(() => _isLoadingMore = false);
        }
      },
      builder: (context, state) {
        final reservePadding = EdgeInsets.only(
          top: _kHeaderReserve,
          bottom: widget.inputReserve,
        );

        if (_messages.isEmpty && state is MessageLoading) {
          return Padding(
            padding: reservePadding,
            child: const Center(child: CupertinoActivityIndicator()),
          );
        }
        if (_messages.isEmpty && state is MessageFailure) {
          return Padding(
            padding: reservePadding,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.error,
                  textAlign: TextAlign.center,
                  style: AppText.mediumTextStyle.copyWith(
                    color: AppColors.greyple,
                  ),
                ),
              ),
            ),
          );
        }
        if (_messages.isEmpty) {
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
          _messages,
          isGroup: widget.chat.isGroupChat,
          currentUserId: widget.currentUserId,
        );
        final itemCount = _messages.length + (_isLoadingMore ? 1 : 0);

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
            return index == -1 ? null : index;
          },
          itemBuilder: (context, index) {
            // Индикатор загрузки — в самом верху (последний элемент при reverse)
            if (_isLoadingMore && index == _messages.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CupertinoActivityIndicator(radius: 10)),
              );
            }

            final grouped = groupedMessages[index];
            final message = grouped.message;

            return RepaintBoundary(
              key: ValueKey(message.id ?? message.localGeneratedId),
              child: MessageItem(
                key: ValueKey(message.id ?? message.localGeneratedId),
                message: message,
                isMine:
                    widget.currentUserId != null &&
                    message.userId == widget.currentUserId,
                showSender: widget.chat.isGroupChat,
                showAvatar: grouped.showAvatar,
                showTime: grouped.showTime,
                tailDirection: grouped.tailDirection,
                hasMessageAbove: grouped.hasMessageAbove,
                onLongPress: () => _showMessageActions(message),
                onTap: () => FocusScope.of(context).unfocus(),
                isLoading: message.hasLoading,
                hasError: message.hasErrorMessage,
              ),
            );
          },
        );
      },
    );
  }

  void _showMessageActions(Message message) {
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
            },
          },
        ),

      // Ответить
      ActionItem(
        icon: CupertinoIcons.arrow_turn_up_left,
        label: 'Ответить',
        onTap: () {
          // TODO: Логика ответа на сообщение
        },
      ),

      // Копировать (только если есть текст)
      if (message.text?.isNotEmpty == true)
        ActionItem(
          icon: CupertinoIcons.square_on_square,
          label: 'Копировать',
          onTap: () {
            // TODO: Копирование в буфер обмена
          },
        ),

      // Переслать
      ActionItem(
        icon: CupertinoIcons.arrow_turn_up_right,
        label: 'Переслать',
        onTap: () {
          // TODO: Логика пересылки
        },
      ),

      // Редактировать (только для своих)
      if (isMyMessage && message.hasError != ActionType.update)
        ActionItem(
          icon: CupertinoIcons.pencil,
          label: 'Редактировать',
          onTap: () {
            widget.onEditMessage(message);
          },
        ),

      // Удалить (только для своих)
      if (isMyMessage && message.hasError != ActionType.delete)
        ActionItem(
          icon: CupertinoIcons.trash,
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
    }
  }
}

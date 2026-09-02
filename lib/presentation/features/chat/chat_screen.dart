import 'dart:ui';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/enums/ui/message_tail_direction.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/message/message_item.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/utils/id_generator.dart';
import 'package:disalive/presentation/utils/message_grouper.dart';
import 'package:disalive/presentation/utils/util_date.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// За сколько пикселей до конца списка подгружать следующую страницу.
const double _kLoadMoreThreshold = 200;

/// Отступ для плавающих хэдера/поля ввода от краёв карточки чата.
const double _kFloatingPanelMargin = 8;

/// Резерв места под хэдер сверху списка сообщений.
const double _kHeaderReserve = 64;

/// Начальный (минимальный) резерв под поле ввода снизу списка.
const double _kInputReserveMin = 76;

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  static Future<void> open(BuildContext context, Chat chat) {
    sl<ChatRepository>().setCurrentChat(chat);
    return SwipeToDismissRoute.push(
      context,
      (context) => ChatScreen(chat: chat),
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController _textController;
  final ValueNotifier<bool> _hasText = ValueNotifier(false);
  int? _editingMessageId;

  late final MessageBloc _messageBloc;
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;

  final GlobalKey _inputKey = GlobalKey();
  double _inputReserve = _kInputReserveMin;

  int? get _currentUserId => sl<UserRepository>().getCurrentUser()?.id;

  bool get _hasEdit => _editingMessageId != null;

  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _textController.addListener(_onTextChanged);

    _messageBloc = sl<MessageBloc>();
    _scrollController.addListener(_onScroll);
    _loadInitial();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureInput());
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (_hasText.value != hasText) {
      _hasText.value = hasText;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureInput());
  }

  void _measureInput() {
    if (!mounted) return;
    final box = _inputKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final measured = box.size.height + _kFloatingPanelMargin;
    if ((measured - _inputReserve).abs() > 1) {
      setState(() => _inputReserve = measured);
    }
  }

  void _loadInitial() {
    _messageBloc.add(
      GetMessages(
        chatId: widget.chat.id,
        entityId: widget.chat.id,
        entityType: EntityType.chat,
        lastIdMessage: 0,
      ),
    );
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
    _messageBloc.add(
      GetMessages(
        chatId: widget.chat.id,
        entityId: widget.chat.id,
        entityType: EntityType.chat,
        lastIdMessage: oldestId,
      ),
    );
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _hasText.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      color: AppColors.mainBackground.withValues(alpha: 0.3),
                      child: Stack(
                        children: [
                          Positioned.fill(child: _buildMessagesArea()),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: _buildHeader(context),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _buildInputArea(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesArea() {
    return BlocConsumer<MessageBloc, MessageState>(
      bloc: _messageBloc,
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
          bottom: _inputReserve,
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
          currentUserId: _currentUserId,
        );
        final itemCount = _messages.length + (_isLoadingMore ? 1 : 0);

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: EdgeInsets.only(
            top: _kHeaderReserve + 8,
            bottom: _inputReserve + 8,
          ),
          itemCount: itemCount,
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

            return MessageItem(
              message: message,
              isMine:
                  _currentUserId != null && message.userId == _currentUserId,
              showSender: widget.chat.isGroupChat,
              showAvatar: grouped.showAvatar,
              showTime: grouped.showTime,
              tailDirection: grouped.tailDirection,
              hasMessageAbove: grouped.hasMessageAbove,
              onLongPress: () => _showMessageActions(message),
              onTap: () => FocusScope.of(context).unfocus(),
              isLoading: message.hasLoading,
              hasError: message.hasErrorMessage,
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _kFloatingPanelMargin,
        _kFloatingPanelMargin,
        _kFloatingPanelMargin,
        0,
      ),
      child: Row(
        children: [
          // Кнопка назад — без фона
          GlassIconButton(
            icon: CupertinoIcons.back,
            onTap: () => Navigator.of(context).pop(),
            size: 36,
          ),
          const SizedBox(width: 12),

          // Аватар и имя — в стеклянной капсуле
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.mainBackground.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 6.0,
                    ),
                    child: Row(
                      children: [
                        BuildAvatar(
                          url: widget.chat.urlAvatar,
                          wh: 26,
                          size: 20,
                          status: widget.chat.user?.status,
                          statusSize: 6,
                          isBookmark: widget.chat.isSoloChat ?? false,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.chat.name,
                            style: AppText.mediumTextStyle.copyWith(
                              color: AppColors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Кнопка звонка — без фона
          if (widget.chat.isSoloChat == false) ...[
            GlassIconButton(
              icon: CupertinoIcons.phone_fill,
              onTap: () {
                // TODO: Инициализация LiveKit для аудио/видео звонков
              },
              size: 36,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      key: _inputKey,
      padding: const EdgeInsets.fromLTRB(
        _kFloatingPanelMargin,
        0,
        _kFloatingPanelMargin,
        _kFloatingPanelMargin,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasEdit) _buildEditBanner(),
          if (_hasEdit) const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GlassIconButton(
                icon: CupertinoIcons.add,
                onTap: () {
                  // TODO: Логика прикрепления медиа
                },
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(_hasEdit ? 8 : 20),
                    topRight: Radius.circular(_hasEdit ? 8 : 20),
                    bottomLeft: const Radius.circular(20),
                    bottomRight: const Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.actionGrey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(_hasEdit ? 8 : 20),
                          topRight: Radius.circular(_hasEdit ? 8 : 20),
                          bottomLeft: const Radius.circular(20),
                          bottomRight: const Radius.circular(20),
                        ),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: CupertinoTextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 5,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        placeholder: 'Сообщение...',
                        placeholderStyle: AppText.mediumTextStyle.copyWith(
                          color: AppColors.greyple,
                        ),
                        style: AppText.mediumTextStyle.copyWith(
                          color: AppColors.white,
                        ),
                        decoration: null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ValueListenableBuilder<bool>(
                valueListenable: _hasText,
                builder: (context, hasText, _) {
                  return GlassIconButton(
                    icon: _hasEdit
                        ? CupertinoIcons.checkmark_alt
                        : hasText
                        ? CupertinoIcons.arrow_up
                        : CupertinoIcons.mic_solid,
                    filled: hasText || _hasEdit,
                    onTap: () {
                      final message = Message(text: _textController.value.text);
                      if (_hasEdit) {
                        _applyEdit(message);
                      } else if (hasText) {
                        sendMessage(message);
                      } else {
                        // TODO: Логика записи голосового сообщения
                      }
                      _textController.clear();
                    },
                    size: 36,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditBanner() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.actionGrey.withValues(alpha: 0.35),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.pencil, size: 14, color: AppColors.linkBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Редактирование сообщения',
                  style: AppText.lowTextStyle.copyWith(
                    color: AppColors.white,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _cancelEdit,
                child: Icon(
                  CupertinoIcons.xmark,
                  size: 16,
                  color: AppColors.greyple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageActions(Message message) {
    final isMyMessage =
        _currentUserId != null && message.userId == _currentUserId;

    var messageRepeat = getMessageRepeat(message);

    final actions = <ActionItem>[
      if (message.hasErrorMessage)
        ActionItem(
          icon: CupertinoIcons.arrow_clockwise,
          label: messageRepeat,
          onTap: () => {
            switch (message.hasError ?? ActionType.create) {
              ActionType.create => sendMessage(message),
              ActionType.update => editMessage(message),
              ActionType.delete => deleteMessage(message),
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
            editMessage(message);
          },
        ),

      // Удалить (только для своих)
      if (isMyMessage && message.hasError != ActionType.delete)
        ActionItem(
          icon: CupertinoIcons.trash,
          label: 'Удалить',
          isDestructive: true,
          onTap: () {
            deleteMessage(message);
          },
        ),
    ];

    ActionBottomSheet.show(
      context,
      title: "Сообщение от ${message.user?.displayName}",
      actions: actions,
    );
  }

  void sendMessage(Message message) {
    var localGeneratedId = '';

    if (message.localGeneratedId != null) {
      localGeneratedId = message.localGeneratedId ?? '';
    } else {
      localGeneratedId = IdGenerator.generateId();
    }

    // Создаем локальное сообщение
    final localMessage = Message(
      localGeneratedId: localGeneratedId,
      chatId: widget.chat.id,
      userId: _currentUserId,
      text: message.text,
      time: DateTime.now().toUtc().toString(),
    );

    _messageBloc.add(
      CreateMessage(
        chatId: widget.chat.id,
        entityId: widget.chat.id,
        entityType: EntityType.chat,
        localGeneratedId: localGeneratedId,
        message: localMessage,
      ),
    );
  }

  void editMessage(Message message) {
    _textController.text = message.text ?? '';
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );

    _editingMessageId = message.id;
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
    });
    _textController.clear();
  }

  void _applyEdit(Message message) {
    if (_editingMessageId == null) return;

    final updatedMessage = Message(
      id: _editingMessageId,
      chatId: widget.chat.id,
      text: message.text,
    );

    _messageBloc.add(
      UpdateMessage(
        chatId: widget.chat.id,
        entityId: widget.chat.id,
        entityType: EntityType.chat,
        message: updatedMessage,
      ),
    );

    _editingMessageId = null;
  }

  void deleteMessage(Message message) {
    _messageBloc.add(
      DeleteMessage(
        chatId: widget.chat.id,
        entityId: widget.chat.id,
        entityType: EntityType.chat,
        messageId: message.getId,
      ),
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

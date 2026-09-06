import 'dart:ui';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat/widgets/chat_header.dart';
import 'package:disalive/presentation/features/chat/widgets/chat_input_area.dart';
import 'package:disalive/presentation/features/chat/widgets/messages_list.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/utils/id_generator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Отступ для плавающих хэдера/поля ввода от краёв карточки чата.
const double _kFloatingPanelMargin = 8;

/// Начальный (минимальный) резерв под поле ввода снизу списка.
const double _kInputReserveMin = 76;

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  static Future<void> open(BuildContext context, Chat chat) {
    ChatBloc chatBloc = context.read<ChatBloc>();
    sl<ChatRepository>().setCurrentChat(chat);
    return SwipeToDismissRoute.push(
      context,
      (context) => BlocProvider.value(
        value: chatBloc,
        child: ChatScreen(chat: chat),
      ),
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<MessagesListState> _messagesListKey =
      GlobalKey<MessagesListState>();
  late final TextEditingController _textController;
  final ValueNotifier<bool> _hasText = ValueNotifier(false);
  final FocusNode _inputFocusNode = FocusNode();
  int? _editingMessageId;
  Message? _answerMessage;

  late final MessageBloc _messageBloc;

  final GlobalKey _inputKey = GlobalKey();
  double _inputReserve = _kInputReserveMin;

  int? get _currentUserId => sl<UserRepository>().getCurrentUser()?.id;

  bool get _hasEdit => _editingMessageId != null;

  late Chat _currentChat;

  @override
  void initState() {
    super.initState();
    _currentChat = widget.chat;
    _textController = TextEditingController();
    _textController.addListener(_onTextChanged);

    _messageBloc = sl<MessageBloc>();
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

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _hasText.dispose();
    _messageBloc.close();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatLoaded) {
          // Ищем обновленный чат в списке
          final updatedChat = state.chats.firstWhere(
            (c) => c.id == _currentChat.id,
            orElse: () => _currentChat,
          );

          if (updatedChat != _currentChat) {
            setState(() {
              _currentChat = updatedChat;
            });
          }
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.transparent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: AppColors.mainBackground,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: TextFieldTapRegion(
                        child: RepaintBoundary(
                          child: MessagesList(
                            key: _messagesListKey,
                            messageBloc: _messageBloc,
                            chat: widget.chat,
                            currentUserId: _currentUserId,
                            inputReserve: _inputReserve,
                            onSendMessage: _onSendMessage,
                            onEditMessage: _onEditMessage,
                            onDeleteMessage: _onDeleteMessage,
                            onAnswerMessage: _onAnswerMessage,
                            onFocusInput: _focusInput,
                            onUnfocusInput: _unfocusInput,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ChatHeader(chat: _currentChat),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ChatInputArea(
                        key: const ValueKey('chat_input_area'),
                        inputKey: _inputKey,
                        textController: _textController,
                        hasEdit: _hasEdit,
                        answerMessage: _answerMessage,
                        hasText: _hasText,
                        cancelBanner: _cancelBanner,
                        onSendMessage: _onSendMessage,
                        onApplyEdit: _onApplyEdit,
                        inputFocusNode: _inputFocusNode,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _focusInput() {
    _inputFocusNode.requestFocus();
  }

  void _unfocusInput() {
    _inputFocusNode.unfocus();
  }

  void _onSendMessage(Message message) {
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
      answerMessageId: _answerMessage?.getId,
      answerMessage: _answerMessage,
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

    if (_answerMessage != null) {
      _cancelBanner();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messagesListKey.currentState?.scrollToBottom(animated: true);
    });
  }

  void _onEditMessage(Message message) {
    _textController.text = message.text ?? '';
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );

    setState(() {
      _answerMessage = null;
      _editingMessageId = message.id;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureInput());
  }

  void _cancelBanner() {
    setState(() {
      _editingMessageId = null;
      _answerMessage = null;
    });
    _textController.clear();
    _unfocusInput();

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureInput());
  }

  void _onApplyEdit(Message message) {
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

    _cancelBanner();
  }

  void _onDeleteMessage(Message message) {
    _messageBloc.add(
      DeleteMessage(
        chatId: widget.chat.id,
        entityId: widget.chat.id,
        entityType: EntityType.chat,
        messageId: message.getId,
      ),
    );
  }

  void _onAnswerMessage(Message message) {
    setState(() {
      _editingMessageId = null;
      _answerMessage = message;
    });

    // Измеряем высоту уже после того, как баннер отрисовался
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusInput();
      _measureInput();
    });
  }
}

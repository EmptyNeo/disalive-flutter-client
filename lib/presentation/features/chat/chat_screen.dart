import 'dart:ui';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/message/message_item.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
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

  late final MessageBloc _messageBloc;
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;

  final GlobalKey _inputKey = GlobalKey();
  double _inputReserve = _kInputReserveMin;

  int? get _currentUserId => sl<UserRepository>().getCurrentUser()?.id;

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
        chatId: widget.chat.chatId ?? 0,
        entityId: widget.chat.chatId ?? 0,
        entityType: EntityType.CHAT,
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
        chatId: widget.chat.chatId ?? 0,
        entityId: widget.chat.chatId ?? 0,
        entityType: EntityType.CHAT,
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
            _isLoadingMore = false;
            if (_messages.isEmpty) _hasMore = false;
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

        final showSender = widget.chat.isGroupChat;
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
            if (_isLoadingMore && index == _messages.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CupertinoActivityIndicator()),
              );
            }
            final message = _messages[index];
            return MessageItem(
              message: message,
              isMine:
                  _currentUserId != null && message.userId == _currentUserId,
              showSender: showSender,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.mainBackground.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  GlassIconButton(
                    icon: CupertinoIcons.back,
                    onTap: () => Navigator.of(context).pop(),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  BuildAvatar(
                    url: widget.chat.urlAvatar,
                    wh: 26,
                    size: 20,
                    status: widget.chat.user?.status,
                    statusSize: 6,
                    statusBackgroundColor: AppColors.lightGrey,
                    isBookmark: widget.chat.isSoloChat ?? false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.chat.name,
                          style: AppText.mediumTextStyle.copyWith(
                            color: AppColors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (widget.chat.isSoloChat == false) ...[
                    GlassIconButton(
                      icon: CupertinoIcons.phone_fill,
                      onTap: () {
                        // TODO: Инициализация LiveKit для аудио/видео звонков
                      },
                      size: 32,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.mainBackground.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.actionGrey.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: CupertinoTextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 3,
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
                  const SizedBox(width: 10),
                  ValueListenableBuilder<bool>(
                    valueListenable: _hasText,
                    builder: (context, hasText, _) {
                      return GlassIconButton(
                        icon: hasText
                            ? CupertinoIcons.arrow_up
                            : CupertinoIcons.mic_solid,
                        filled: hasText,
                        onTap: () {
                          if (hasText) {
                            // TODO: Логика отправки текста
                            _textController.clear();
                          } else {
                            // TODO: Логика записи голосового сообщения
                          }
                        },
                        size: 36,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

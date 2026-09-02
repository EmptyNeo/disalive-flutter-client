import 'dart:ui';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/enums/ui/message_tail_direction.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/message/message_item.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
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
            _isLoadingMore = state.isLoadingMore; // Используем флаг из bloc
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

        final isGroup = widget.chat.isGroupChat;
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
            final message = _messages[index];
            final nextMessage = index > 0
                ? _messages[index - 1]
                : null; // Ниже (новое)
            final prevMessage = index < _messages.length - 1
                ? _messages[index + 1]
                : null; // Выше (старое)
            final prevPrevMessage =
                prevMessage != null && index < _messages.length - 2
                ? _messages[index + 2]
                : null;

            // Функция проверки интервала 5 минут
            bool isWithin5Minutes(Message? m1, Message? m2) {
              if (m1 == null || m2 == null) return false;
              if (m1.userId != m2.userId) return false;
              final t1 = UtilDate.parseDateTime(m1.time);
              final t2 = UtilDate.parseDateTime(m2.time);
              if (t1 == null || t2 == null) return false;
              return t1.difference(t2).abs() <= const Duration(minutes: 5);
            }

            final hasSameUserAbove = isWithin5Minutes(
              message,
              prevMessage,
            ); // Есть ли сосед выше (старее)
            final hasSameUserBelow = isWithin5Minutes(
              message,
              nextMessage,
            ); // Есть ли сосед ниже (новее)

            final bool isMine =
                _currentUserId != null && message.userId == _currentUserId;
            final isOtherUserInGroup = isGroup && !isMine;

            MessageTailDirection tailDirection;
            bool showTime;
            bool showAvatarForGroup = false;

            if (isOtherUserInGroup) {
              // --- TELEGRAM-СТИЛЬ ДЛЯ ЧУЖИХ СООБЩЕНИЙ В ГРУППЕ ---
              if (!hasSameUserAbove && !hasSameUserBelow) {
                // 1. Единственное сообщение: хвост вниз, аватар есть, время есть, верх круглый
                tailDirection = MessageTailDirection.down;
                showTime = true;
                showAvatarForGroup = true;
              } else if (!hasSameUserAbove && hasSameUserBelow) {
                // 2. Первое (самое верхнее/старое) сообщение в пачке: хвост вниз, без аватара, верх круглый (без стыков)
                tailDirection = MessageTailDirection.down;
                showTime = false;
                showAvatarForGroup = false;
              } else if (hasSameUserAbove && hasSameUserBelow) {
                // 3. Среднее сообщение в пачке: без хвоста (squareRadius), без аватара
                tailDirection = MessageTailDirection.none;
                showTime = false;
                showAvatarForGroup = false;
              } else {
                // 4. Последнее (самое нижнее/новое) сообщение в пачке: хвост вниз (к аватару), аватар есть, верх плоский (стыкуется)
                tailDirection = MessageTailDirection.down;
                showTime = true;
                showAvatarForGroup = true;
              }
            } else {
              // --- СТРОГАЯ ЛОГИКА ДЛЯ ЛИЧНЫХ ЧАТОВ И МОИХ СООБЩЕНИЙ (isMine) ---
              if (!hasSameUserAbove && !hasSameUserBelow) {
                tailDirection = MessageTailDirection.up;
                showTime = true;
                showAvatarForGroup = false;
              } else if (!hasSameUserAbove && hasSameUserBelow) {
                tailDirection = MessageTailDirection.down;
                showTime = true;
                showAvatarForGroup = false;
              } else if (hasSameUserAbove && hasSameUserBelow) {
                tailDirection = MessageTailDirection.none;
                showTime = false;
                showAvatarForGroup = false;
              } else {
                tailDirection = MessageTailDirection.up;
                final bool hasSomeoneAbovePrev = isWithin5Minutes(
                  prevMessage,
                  prevPrevMessage,
                );
                showTime = !hasSomeoneAbovePrev;
                showAvatarForGroup = false;
              }
            }

            return MessageItem(
              message: message,
              isMine: isMine,
              showSender: isGroup,
              // Всегда передаем true для групп, чтобы сохранять отступ
              showAvatar: showAvatarForGroup,
              // Аватар рисуем только у последнего/единственного
              showTime: showTime,
              tailDirection: tailDirection,
              hasMessageAbove: hasSameUserAbove,
              // <--- КРИТИЧЕСКИ ВАЖНО: передаем наличие соседа сверху для плоского верхнего угла
              onLongPress: () => _showMessageActions(message),
              onTap: () => FocusScope.of(context).unfocus(),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.actionGrey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
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
    );
  }

  void _showMessageActions(Message message) {
    final isMyMessage =
        _currentUserId != null && message.userId == _currentUserId;

    final actions = <ActionItem>[
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
      if (isMyMessage)
        ActionItem(
          icon: CupertinoIcons.pencil,
          label: 'Редактировать',
          onTap: () {
            // _editMessage(message);
          },
        ),

      // Удалить (только для своих)
      if (isMyMessage)
        ActionItem(
          icon: CupertinoIcons.trash,
          label: 'Удалить',
          isDestructive: true,
          onTap: () {
            // _confirmDeleteMessage(message);
          },
        ),
    ];

    ActionBottomSheet.show(
      context,
      title: "Сообщение от ${message.user?.displayName}",
      actions: actions,
    );
  }
}

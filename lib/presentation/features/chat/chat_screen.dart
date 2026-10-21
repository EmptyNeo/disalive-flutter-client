// lib/presentation/features/chat/chat_screen.dart
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/data/repositories/local_chat_state_repository.dart';
import 'package:disalive/domain/enums/file_content_type.dart';
import 'package:disalive/domain/enums/file_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/responses/symbol_data.dart';
import 'package:disalive/domain/models/sticker_content.dart';
import 'package:disalive/domain/models/ui/chat_attachment.dart';
import 'package:disalive/domain/models/ui/meta_file_message.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/calls_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/determining_context_service.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/calls/bloc/call_participants_bloc.dart';
import 'package:disalive/presentation/features/calls/bloc/call_bloc.dart';
import 'package:disalive/presentation/features/calls/call_screen.dart';
import 'package:disalive/presentation/features/calls/widgets/call_activity_banner.dart';
import 'package:disalive/presentation/features/chat/screens/search_messages_screen.dart';
import 'package:disalive/presentation/features/chat/widgets/chat_header.dart';
import 'package:disalive/presentation/features/chat/widgets/chat_input_area.dart';
import 'package:disalive/presentation/features/chat/widgets/messages_list.dart';
import 'package:disalive/presentation/features/chat/widgets/symbols/chat_extra_panel.dart';
import 'package:disalive/presentation/features/chat_server/bloc/chat_server_bloc.dart';
import 'package:disalive/presentation/features/gifs/bloc/gif_bloc.dart';
import 'package:disalive/presentation/features/invites/bloc/invites_bloc.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/media_stats/bloc/media_stats_bloc.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/profile/determinant_profile_screen.dart';
import 'package:disalive/presentation/features/reactions/bloc/preferred_reactions_bloc.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/stickers/bloc/stickers_pack_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/utils/id_generator.dart';
import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:disalive/presentation/utils/ui/util_file.dart';
import 'package:disalive/presentation/widgets/emoji_text_editing_controller.dart';
import 'package:disalive/presentation/widgets/media_picker_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p show basename;

/// Отступ для плавающих хэдера/поля ввода от краёв карточки чата.
const double _kFloatingPanelMargin = 8;

/// Начальный (минимальный) резерв под поле ввода снизу списка.
const double _kInputReserveMin = 76;

int? initialPositionForChat(Chat chat, int? savedPositionId) {
  if (chat.type == ChatType.channel) {
    return null;
  }
  return savedPositionId;
}

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  static Future<void> open(BuildContext context, Chat chat, bool isReconnect) {
    ChatBloc chatBloc = context.read<ChatBloc>();
    MessageBloc messageBloc = context.read<MessageBloc>();
    ChatServerBloc chatServerBloc = context.read<ChatServerBloc>();
    MembersBloc membersBloc = context.read<MembersBloc>();
    GifBloc gifBloc = context.read<GifBloc>();
    StickersPackBloc stickerBloc = context.read<StickersPackBloc>();
    PreferredReactionsBloc preferredReactionsBloc = context
        .read<PreferredReactionsBloc>();
    final invitesBloc = context.read<InvitesBloc>();
    final mediaStatsBloc = context.read<MediaStatsBloc>();
    final serversBloc = context.read<ServersBloc>();
    final callBloc = context.read<CallBloc>();
    sl<ChatRepository>().setCurrentChat(chat);

    return SwipeToDismissRoute.push(
      context,
      (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: chatBloc),
          BlocProvider.value(value: messageBloc),
          BlocProvider.value(value: chatServerBloc),
          BlocProvider.value(value: membersBloc),
          BlocProvider.value(value: gifBloc),
          BlocProvider.value(value: stickerBloc),
          BlocProvider.value(value: preferredReactionsBloc),
          BlocProvider.value(value: invitesBloc),
          BlocProvider.value(value: mediaStatsBloc),
          BlocProvider.value(value: serversBloc),
          BlocProvider.value(value: callBloc),
        ],
        child: ChatScreen(chat: chat),
      ),
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final GlobalKey<MessagesListState> _messagesListKey =
      GlobalKey<MessagesListState>();
  late final EmojiTextEditingController _textController;
  final ValueNotifier<bool> _hasNeedSend = ValueNotifier(false);
  final FocusNode _inputFocusNode = FocusNode();
  List<ChatAttachment> _attachments = [];
  final List<ChatAttachment> _deletedAttachments = [];
  int? _editingMessageId;
  Message? _answerMessage;
  bool isReconnect = false;
  late final int? _draftUserId;
  Timer? _draftTimer;
  bool _restoringDraft = false;
  int? _initialPositionId;

  late final MessageBloc _messageBloc;
  late final ChatBloc _chatBloc;
  late final CallParticipantsBloc _callParticipantsBloc;

  final GlobalKey _inputKey = GlobalKey();
  double _inputReserve = _kInputReserveMin;

  int? get _currentUserId => sl<UserRepository>().getCurrentUser()?.id;

  bool get _hasEdit => _editingMessageId != null;

  bool get _hasAnswer => _answerMessage != null;

  Future<void> _openCall() async {
    final chat = _currentChat;
    final announceCall = !_callParticipantsBloc.state.hasParticipants(chat.id);
    final serverId = chat.type == ChatType.channel
        ? sl<ServerRepository>().selectedServerId
        : null;
    if (chat.type == ChatType.channel && serverId == null) return;
    final entityKey = EntityKey(
      entityId: serverId ?? chat.id,
      entityType: serverId == null ? EntityType.chat : EntityType.server,
    );
    _callParticipantsBloc.add(const StopWatchingCallParticipants());
    try {
      await CallScreen.open(
        context,
        chatId: chat.id,
        entityKey: entityKey,
        title: chat.name,
        lastIdMessage: chat.idLastMessage,
        announceCall: announceCall,
      );
    } finally {
      if (mounted) {
        _callParticipantsBloc.add(
          WatchCallParticipants(entityKey, chatId: chat.id),
        );
      }
    }
  }

  late Chat _currentChat;
  StreamSubscription? _channelReadSubscription;
  StreamSubscription? _channelMessageSubscription;

  bool _hasUnread(Chat chat) {
    if (chat.type == ChatType.channel) {
      return (chat.newMessagesCount ?? 0) > 0;
    }
    final lastRead = chat.member?.lastIdReadMessage ?? 0;
    return lastRead > 0 && (chat.idLastMessage ?? 0) > lastRead;
  }

  bool _isExtraPanelOpen = false;
  final double _extraPanelHeight = 335;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _draftUserId = _currentUserId;
    sl<LocalChatStateRepository>().allowDraftsForUser(_draftUserId);
    _currentChat = widget.chat;
    _textController = EmojiTextEditingController();
    _textController.addListener(_onTextChanged);

    _messageBloc = context.read<MessageBloc>();
    _chatBloc = context.read<ChatBloc>();
    _callParticipantsBloc = CallParticipantsBloc(sl<CallsRepository>());
    if (_currentChat.isSoloChat != true) {
      final serverId = _currentChat.type == ChatType.channel
          ? sl<ServerRepository>().selectedServerId
          : null;
      if (_currentChat.type != ChatType.channel || serverId != null) {
        _callParticipantsBloc.add(
          WatchCallParticipants(
            EntityKey(
              entityId: serverId ?? _currentChat.id,
              entityType: serverId == null
                  ? EntityType.chat
                  : EntityType.server,
            ),
            chatId: _currentChat.id,
          ),
        );
      }
    }
    if (_currentChat.type == ChatType.channel) _listenToChannelEvents();
    _restoreDraft();
    final savedPositionId = sl<LocalChatStateRepository>()
        .getFirstVisibleMessageId(_draftUserId, widget.chat.id);
    _initialPositionId = initialPositionForChat(_currentChat, savedPositionId);
    _loadInitial();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureInput());
    context.read<PreferredReactionsBloc>().add(const LoadPreferredReactions());

    _inputFocusNode.addListener(_handleFocusChange);
  }

  void _listenToChannelEvents() {
    final bus = sl<WsEventBus>();
    _channelReadSubscription = bus.subscribe(
      table: 'ChatMembers',
      action: ActionType.update,
      onData: (event) {
        if (event.data['entityType'] != 'server' ||
            !(DataParser.parseBool(event.data['isSelf']) ?? event.isSelf) ||
            DataParser.parseInt(event.data['chatId']) != _currentChat.id) {
          return;
        }
        final raw = event.data['member'];
        if (raw is! Map) return;
        final memberData = Map<String, dynamic>.from(raw);
        final readId = DataParser.parseInt(memberData['lastIdReadMessage']);
        if (readId == null) return;
        final previousRead = _currentChat.member?.lastIdReadMessage ?? 0;
        if (readId < previousRead) return;
        final loaded = _messageBloc.state;
        final readMessages = loaded is MessageLoaded
            ? loaded.messages.where((message) {
                final id = message.id;
                return id != null && id > previousRead && id <= readId;
              }).length
            : 0;
        final newestLoaded =
            loaded is MessageLoaded && loaded.messages.isNotEmpty
            ? loaded.messages.first.id ?? 0
            : 0;
        final latestId = math.max(
          _currentChat.idLastMessage ?? 0,
          newestLoaded,
        );
        final serverCount = DataParser.parseInt(memberData['newMessagesCount']);
        final nextCount =
            serverCount ??
            (latestId > 0 && readId >= latestId
                ? 0
                : math.max(
                    0,
                    (_currentChat.newMessagesCount ?? 0) - readMessages,
                  ));
        if (!mounted) return;
        setState(() {
          _currentChat = _currentChat.copyWith(
            member: (_currentChat.member ?? const Member()).copyWith(
              lastIdReadMessage: readId,
            ),
            newMessagesCount: nextCount,
          );
        });
      },
    );
    _channelMessageSubscription = bus.subscribe(
      table: 'Message',
      action: ActionType.create,
      onData: (event) {
        final raw = event.data['message'];
        if (raw is! Map) return;
        final message = Map<String, dynamic>.from(raw);
        final chatId = DataParser.parseInt(
          message['chatId'] ?? event.data['chatId'],
        );
        final id = DataParser.parseInt(message['id']);
        if (chatId != _currentChat.id || id == null || !mounted) return;
        if (id <= (_currentChat.idLastMessage ?? 0)) return;
        setState(() {
          _currentChat = _currentChat.copyWith(
            idLastMessage: id,
            newMessagesCount:
                (_currentChat.newMessagesCount ?? 0) + (event.isSelf ? 0 : 1),
          );
        });
      },
    );
  }

  void _handleFocusChange() {
    if (_isExtraPanelOpen && _inputFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isExtraPanelOpen && _inputFocusNode.hasFocus) {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        }
      });
    }
  }

  void _onTextChanged() {
    _onChangedNeedSend();
    _scheduleDraftSave();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureInput());
  }

  void _restoreDraft() {
    final draft = sl<LocalChatStateRepository>().getDraft(
      _draftUserId,
      widget.chat.id,
    );
    if (draft == null) return;
    _restoringDraft = true;
    _textController.text = draft.text;
    _attachments = draft.attachments
        .where(
          (attachment) =>
              attachment.file == null || attachment.file!.existsSync(),
        )
        .toList();
    _deletedAttachments.addAll(draft.deletedAttachments);
    _answerMessage = draft.answerMessage;
    _editingMessageId = draft.editingMessageId;
    _onChangedNeedSend();
    _restoringDraft = false;
  }

  void _scheduleDraftSave() {
    if (_restoringDraft) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 300), _saveDraft);
  }

  void _saveDraft() {
    _draftTimer?.cancel();
    sl<LocalChatStateRepository>().saveDraft(
      _draftUserId,
      widget.chat.id,
      ChatDraft(
        text: _textController.text,
        attachments: List.of(_attachments),
        deletedAttachments: List.of(_deletedAttachments),
        answerMessage: _answerMessage,
        editingMessageId: _editingMessageId,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _saveDraft();
      _savePosition();
    }
  }

  void _savePosition() {
    final id = _messagesListKey.currentState?.firstVisibleMessageId();
    if (id != null) {
      sl<LocalChatStateRepository>().saveFirstVisibleMessageId(
        _draftUserId,
        widget.chat.id,
        id,
      );
    }
  }

  void _onChangedNeedSend() {
    final hasText = _textController.text.trim().isNotEmpty;
    final hasAttachments = _attachments.isNotEmpty;
    _hasNeedSend.value = hasAttachments || hasText;
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

  void _toggleExtraPanel({bool requestFocus = true}) {
    setState(() {
      _isExtraPanelOpen = !_isExtraPanelOpen;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_isExtraPanelOpen) {
        if (requestFocus) {
          _inputFocusNode.requestFocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        }
      } else {
        if (requestFocus) {
          _inputFocusNode.requestFocus();
          SystemChannels.textInput.invokeMethod('TextInput.show');
        }
      }
    });
  }

  void _insertEmoji(String fullEmojiId) {
    // Гарантируем, что поле активно, а клавиатура скрыта
    _inputFocusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => SystemChannels.textInput.invokeMethod('TextInput.hide'),
    );

    final currentText = _textController.text;
    final currentSelection = _textController.selection;

    final insertPosition = currentSelection.isCollapsed
        ? currentSelection.start
        : currentText.length;

    final emojiWithSpace = '$fullEmojiId ';

    final newText = currentText.replaceRange(
      currentSelection.start,
      currentSelection.end,
      emojiWithSpace,
    );

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: insertPosition + emojiWithSpace.length,
      ),
    );

    _onTextChanged();
  }

  void _deleteLastEmojiOrChar() {
    final currentText = _textController.text;
    final currentSelection = _textController.selection;

    // Если есть выделение, просто удаляем его (стандартное поведение)
    if (!currentSelection.isCollapsed) {
      final newText = currentText.replaceRange(
        currentSelection.start,
        currentSelection.end,
        '',
      );
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: currentSelection.start),
      );
      _onTextChanged();
      return;
    }

    if (currentSelection.start == 0) return; // Нечего удалять

    final textBeforeCursor = currentText.substring(0, currentSelection.start);

    // 🎯 Регекс ищет паттерн [category:id] с возможным пробелом на конце строки
    final regex = RegExp(r'\[[a-zA-Z0-9_]+:\d+\]\s?$');
    final match = regex.firstMatch(textBeforeCursor);

    String newText;
    int newCursorOffset;

    if (match != null) {
      // Удаляем весь тег эмодзи целиком
      newText = currentText.replaceRange(
        match.start,
        currentSelection.start,
        '',
      );
      newCursorOffset = match.start;
    } else {
      // Стандартное удаление: стираем 1 последний символ
      newText = currentText.replaceRange(
        currentSelection.start - 1,
        currentSelection.start,
        '',
      );
      newCursorOffset = currentSelection.start - 1;
    }

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
    _onTextChanged();
  }

  Future<void> _onSearchTap() async {
    final selectedMessage = await SearchMessagesScreen.open(
      context,
      _currentChat,
      onTapSticker,
      _sendInviteRequest,
    );

    if (selectedMessage != null && mounted) {
      // Передаём управление в MessagesList для навигации с подсветкой
      _messagesListKey.currentState?.navigateToPublic(
        selectedMessage.id,
        highlight: true,
      );
    }
  }

  void _loadInitial() {
    final entity = DeterminingContextService.getEntityKey();
    if (entity == null) return;
    final originalLastIdRead = _currentChat.member?.lastIdReadMessage ?? 0;
    final lastReadId = math.max(
      0,
      originalLastIdRead - 2,
    ); // -2 для того, чтобы загрузить немного старых
    final hasUnread = _hasUnread(_currentChat);
    final initialAroundId =
        _initialPositionId ??
        (hasUnread && originalLastIdRead > 0 ? lastReadId : null);

    _messageBloc.add(
      GetMessages(
        chatId: widget.chat.id,
        entityId: entity.entityId,
        entityType: entity.entityType,
        lastIdMessage: 0,
        aroundId: initialAroundId,
        limit: 25,
      ),
    );
  }

  @override
  void dispose() {
    _callParticipantsBloc.close();
    _channelReadSubscription?.cancel();
    _channelMessageSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _saveDraft();
    _savePosition();
    _inputFocusNode.removeListener(_handleFocusChange);
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _hasNeedSend.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 1. Оборачиваем весь экран в PopScope для перехвата кнопки "Назад"
    return PopScope(
      // Разрешаем стандартный pop (выход из экрана) ТОЛЬКО если панель закрыта
      canPop: !_isExtraPanelOpen,

      // 🎯 2. Перехватываем действие "Назад"
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          _saveDraft();
          _savePosition();
          return;
        }

        if (_isExtraPanelOpen) {
          // Если панель открыта, закрываем её и возвращаем фокус/клавиатуру
          _toggleExtraPanel(requestFocus: false);
        }
      },

      child: MultiBlocListener(
        listeners: [
          BlocListener<ChatBloc, ChatState>(
            listener: (context, state) {
              if (state is ChatLoaded) {
                if (_currentChat.type == ChatType.channel) return;
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
          ),
          BlocListener<ChatServerBloc, ChatServerState>(
            listener: (context, state) {
              final shouldShowReconnect = state is! ChatServerConnected;

              if (isReconnect != shouldShowReconnect) {
                setState(() {
                  isReconnect = shouldShowReconnect;
                });
              }
            },
          ),
        ],
        child: CupertinoPageScaffold(
          backgroundColor: CupertinoColors.transparent,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
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
                        child:
                            BlocBuilder<
                              CallParticipantsBloc,
                              CallParticipantsState
                            >(
                              bloc: _callParticipantsBloc,
                              buildWhen: (previous, current) =>
                                  previous.hasParticipants(_currentChat.id) !=
                                  current.hasParticipants(_currentChat.id),
                              builder: (context, callState) => RepaintBoundary(
                                child: MessagesList(
                                  key: _messagesListKey,
                                  messageBloc: _messageBloc,
                                  chatBloc: _chatBloc,
                                  chat: _currentChat,
                                  currentUserId: _currentUserId,
                                  initialAroundId: _hasUnread(_currentChat)
                                      ? (_currentChat
                                                .member
                                                ?.lastIdReadMessage ??
                                            0)
                                      : null,
                                  initialPositionId: _initialPositionId,
                                  inputReserve:
                                      _inputReserve +
                                      (_isExtraPanelOpen
                                          ? _extraPanelHeight
                                          : 0),
                                  headerReserve:
                                      callState.hasParticipants(_currentChat.id)
                                      ? 116
                                      : 64,
                                  onSendMessage: _onSendMessage,
                                  onEditMessage: _onEditMessage,
                                  onDeleteMessage: _onDeleteMessage,
                                  onAnswerMessage: _onAnswerMessage,
                                  onFocusInput: _focusInput,
                                  onUnfocusInput: _unfocusInput,
                                  onStickerTap: onTapSticker,
                                  onInviteMention: _sendInviteRequest,
                                ),
                              ),
                            ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child:
                            BlocBuilder<
                              CallParticipantsBloc,
                              CallParticipantsState
                            >(
                              bloc: _callParticipantsBloc,
                              buildWhen: (previous, current) =>
                                  previous.participants
                                      .forChat(_currentChat.id)
                                      .length !=
                                  current.participants
                                      .forChat(_currentChat.id)
                                      .length,
                              builder: (context, callState) =>
                                  BlocBuilder<CallBloc, CallState>(
                                    builder: (context, activeCall) {
                                      final isCurrentCall =
                                          activeCall.chatId ==
                                              _currentChat.id &&
                                          (activeCall.status ==
                                                  CallStatus.connected ||
                                              activeCall.status ==
                                                  CallStatus.connecting);
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ChatHeader(
                                            chat: _currentChat,
                                            isReconnect: isReconnect,
                                            hasActiveCall: callState
                                                .hasParticipants(
                                                  _currentChat.id,
                                                ),
                                            isCurrentCall: isCurrentCall,
                                            onCallTap: _openCall,
                                            onTap: () =>
                                                DeterminantProfileScreen.open(
                                                  context,
                                                  chat: widget.chat,
                                                ),
                                            onSearchTap: _onSearchTap,
                                          ),
                                          if (callState.hasParticipants(
                                            _currentChat.id,
                                          ))
                                            CallActivityBanner(
                                              participantCount: callState
                                                  .participants
                                                  .forChat(_currentChat.id)
                                                  .length,
                                              isCurrentCall: isCurrentCall,
                                              onJoin: _openCall,
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                            ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          height: _isExtraPanelOpen ? _extraPanelHeight : 0,
                          child: _isExtraPanelOpen
                              ? ChatExtraPanel(
                                  height: _extraPanelHeight,
                                  onClose: _toggleExtraPanel,
                                  onTapEmoji: (emoji) {
                                    String fullEmojiId =
                                        '[${emoji.categoryName}:${emoji.id}]';
                                    _insertEmoji(fullEmojiId);
                                  },
                                  onTapSticker: onTapSticker,
                                  onTapGif: (gif) {
                                    final optimisticFileMessage = FileMessage(
                                      id: -1,
                                      messageId: null,
                                      pathFile: gif.fullUrl,
                                      originalName: 'gif',
                                      size: 0,
                                      unit: 'B',
                                      fileType: FileType.image,
                                      contentType: FileContentType.gif,
                                      duration: 0,
                                      isSpoiler: 0,
                                    );

                                    final symbolData = SymbolData(
                                      filePath: gif.fullUrl,
                                      typeFile: FileContentType.gif,
                                    );

                                    final message = Message(
                                      attachments: [optimisticFileMessage],
                                      symbolData: symbolData,
                                    );

                                    _onSendMessage(message);
                                  },
                                  onBackspace: _deleteLastEmojiOrChar,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        left: 0,
                        right: 0,
                        bottom: _isExtraPanelOpen ? _extraPanelHeight : 0,
                        child: ChatInputArea(
                          key: const ValueKey('chat_input_area'),
                          chat: _currentChat,
                          inputKey: _inputKey,
                          textController: _textController,
                          hasEdit: _hasEdit,
                          hasAnswer: _hasAnswer,
                          answerMessage: _answerMessage,
                          hasNeedSend: _hasNeedSend,
                          cancelBanner: _cancelBanner,
                          onSendMessage: _onSendMessage,
                          onApplyEdit: _onApplyEdit,
                          inputFocusNode: _inputFocusNode,
                          isReconnect: isReconnect,
                          attachments: _attachments,
                          onPickAttachment: _pickAttachments,
                          onRemoveAttachment: (attachment) {
                            setState(() {
                              if (!attachment.isNew && attachment.id != null) {
                                attachment.isDeleted = true;
                                _deletedAttachments.add(attachment);
                              }
                              _attachments.remove(attachment);
                              _scheduleDraftSave();
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _measureInput(),
                              );
                            });
                          },
                          onUpdateAttachment: (updatedAttachment) {
                            setState(() {
                              final index = _attachments.indexWhere((a) {
                                if (a.id != null &&
                                    updatedAttachment.id != null) {
                                  return a.id == updatedAttachment.id;
                                }
                                if (a.file != null &&
                                    updatedAttachment.file != null) {
                                  return a.file!.path ==
                                      updatedAttachment.file!.path;
                                }
                                return false;
                              });
                              if (index != -1) {
                                _attachments[index] = updatedAttachment;
                              }
                              _scheduleDraftSave();
                            });
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _measureInput(),
                            );
                          },
                          onSendVoiceMessage: _onSendVoiceMessage,
                          onToggleExtraPanel: _toggleExtraPanel,
                          onHideKeyboard: () {
                            if (_inputFocusNode.hasFocus) {
                              _inputFocusNode.unfocus();
                            }
                          },
                          isExtraPanelOpen: _isExtraPanelOpen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onTapSticker(StickerContent sticker) {
    final optimisticFileMessage = FileMessage(
      id: -1,
      messageId: null,
      pathFile: sticker.urlPath,
      originalName: 'sticker',
      size: 0,
      unit: 'B',
      fileType: FileType.image,
      contentType: FileContentType.sticker,
      duration: 0,
      isSpoiler: 0,
    );

    final symbolData = SymbolData(
      filePath: sticker.urlPath,
      typeFile: FileContentType.sticker,
      packId: sticker.packId,
    );

    final message = Message(
      attachments: [optimisticFileMessage],
      symbolData: symbolData,
    );

    _onSendMessage(message);
  }

  void _focusInput() {
    _inputFocusNode.requestFocus();
  }

  void _unfocusInput() {
    _inputFocusNode.unfocus();
  }

  Future<void> _pickAttachments() async {
    final files = await MediaPickerBottomSheet.open(
      context: context,
      allowMultiple: true,
    );

    if (files != null && files.isNotEmpty) {
      setState(() {
        for (final file in files) {
          final name = p.basename(file.path);

          final mimeType = lookupMimeType(file.path);
          final fileType = FileType.fromMimeType(mimeType);

          final sizeBytes = file.lengthSync();
          (double, String) unit = UtilFile.getFileSizeAndUnit(sizeBytes);

          _attachments.add(
            ChatAttachment(
              file: file,
              name: name,
              size: unit.$1,
              unit: unit.$2,
              fileType: fileType,
              contentType: FileContentType.defaultFile,
            ),
          );
        }
      });
      final hasAttachments = _attachments.isNotEmpty;
      if (hasAttachments) {
        _hasNeedSend.value = hasAttachments;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureInput());
      _scheduleDraftSave();
    }
  }

  List<FileMessage> convertFilesToAttachments(
    List<ChatAttachment> attachments,
  ) {
    final localAttachments = <FileMessage>[];
    for (int i = 0; i < attachments.length; i++) {
      final att = attachments[i];
      if (!att.isDeleted) {
        localAttachments.add(att.toFileMessage(i));
      }
    }
    return localAttachments;
  }

  void _onSendMessage(Message message) {
    final entity = DeterminingContextService.getEntityKey();
    if (entity == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messagesListKey.currentState?.handleScrollToBottom(animated: false);
    });

    var localGeneratedId = message.localGeneratedId ?? IdGenerator.generateId();

    final metaNewFiles = <MetaFileMessage>[];
    final newFilesList = <File>[];

    if (message.attachments != null && message.attachments!.isNotEmpty) {
      for (int i = 0; i < message.attachments!.length; i++) {
        final att = message.attachments![i];
        if (att.pathFile != null && att.pathFile!.isNotEmpty) {
          final file = File(att.pathFile!);
          if (file.existsSync()) {
            newFilesList.add(file);
            metaNewFiles.add(
              MetaFileMessage(
                index: i,
                duration: att.duration,
                isSpoiler: att.isSpoiler == 1,
                deleted: false,
                changed: false,
              ),
            );
          }
        }
      }
    }
    // 🎯 2. Иначе берем файлы из текущего состояния _attachments (стандартная новая отправка)
    else {
      int fileIndex = 0;
      for (final att in _attachments) {
        if (att.isNew && !att.isDeleted) {
          newFilesList.add(att.file!);
          metaNewFiles.add(
            MetaFileMessage(
              index: fileIndex,
              duration: att.duration,
              isSpoiler: att.isSpoiler,
              deleted: false,
              changed: false,
            ),
          );
          fileIndex++;
        }
      }
    }

    final localAttachments =
        (message.attachments != null && message.attachments!.isNotEmpty)
        ? message.attachments!
        : convertFilesToAttachments(_attachments);

    final localMessage = Message(
      localGeneratedId: localGeneratedId,
      chatId: widget.chat.id,
      userId: _currentUserId,
      text: message.text,
      time: DateTime.now().toUtc().toString(),
      answerMessageId: message.answerMessageId ?? _answerMessage?.getId,
      answerMessage: message.answerMessage ?? _answerMessage,
      attachments: localAttachments.isEmpty ? null : localAttachments,
      newFiles: newFilesList.isEmpty ? null : newFilesList,
      metaNewFilesMessage: metaNewFiles.isEmpty ? null : metaNewFiles,
      user: sl<UserRepository>().getCurrentUser(),
    );

    _messageBloc.add(
      CreateMessage(
        chatId: widget.chat.id,
        entityId: entity.entityId,
        entityType: entity.entityType,
        localGeneratedId: localGeneratedId,
        message: localMessage,
        symbolData: message.symbolData,
      ),
    );

    if (_answerMessage != null || _attachments.isNotEmpty) {
      _cancelBanner();
    }

    _clearAllAttachments();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messagesListKey.currentState?.scrollToBottom(animated: true);
    });
  }

  void _sendInviteRequest(String text) {
    final entity = DeterminingContextService.getEntityKey();
    if (entity == null) return;
    final localId = IdGenerator.generateId();
    _messageBloc.add(
      CreateMessage(
        chatId: widget.chat.id,
        entityId: entity.entityId,
        entityType: entity.entityType,
        localGeneratedId: localId,
        message: Message(
          localGeneratedId: localId,
          chatId: widget.chat.id,
          userId: _currentUserId,
          text: text,
          time: DateTime.now().toUtc().toString(),
          user: sl<UserRepository>().getCurrentUser(),
        ),
      ),
    );
  }

  void _onEditMessage(Message message) {
    if (_isExtraPanelOpen) {
      _toggleExtraPanel();
    }

    _textController.text = message.text ?? '';
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );

    setState(() {
      _answerMessage = null;
      _editingMessageId = message.id;

      _attachments = (message.attachments ?? []).map((fileMsg) {
        return ChatAttachment(
          id: fileMsg.id,
          file: null,
          url: fileMsg.urlPath,
          name: fileMsg.originalName ?? 'Файл',
          size: fileMsg.size ?? 0,
          unit: fileMsg.unit ?? 'Б',
          fileType: fileMsg.fileType,
          contentType: fileMsg.contentType,
          duration: fileMsg.duration,
          isSpoiler: fileMsg.isSpoiler == 1,
          isDeleted: false,
        );
      }).toList();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureInput());
    _scheduleDraftSave();
  }

  void _onSendVoiceMessage(File file, double durationSeconds) {
    final entity = DeterminingContextService.getEntityKey();
    if (entity == null) return;
    var localGeneratedId = IdGenerator.generateId();
    final bytes = file.lengthSync();
    final (sizeVal, sizeUnit) = UtilFile.getFileSizeAndUnit(bytes);

    // 🎯 1. Формируем списки для отправки на сервер (как мы делали с обычными файлами)
    final newFilesList = <File>[file];
    final metaNewFilesList = <MetaFileMessage>[
      MetaFileMessage(
        index: 0,
        name: "Голосовое сообщение.m4a",
        duration: durationSeconds,
        isSpoiler: false,
        deleted: false,
        changed: false,
      ),
    ];

    // 🎯 2. Создаем локальное сообщение для мгновенного отображения в чате
    final localMessage = Message(
      localGeneratedId: localGeneratedId,
      chatId: widget.chat.id,
      userId: _currentUserId,
      text: '',
      time: DateTime.now().toUtc().toString(),
      answerMessageId: _answerMessage?.getId,
      answerMessage: _answerMessage,
      attachments: [
        FileMessage(
          id: -1,
          messageId: null,
          pathFile: file.path,
          originalName: 'Голосовое сообщение.m4a',
          size: sizeVal,
          unit: sizeUnit,
          fileType: FileType.audio,
          contentType: FileContentType.voice,
          duration: durationSeconds,
          isSpoiler: 0,
        ),
      ],
      newFiles: newFilesList,
      metaNewFilesMessage: metaNewFilesList,
    );

    _messageBloc.add(
      CreateMessage(
        chatId: widget.chat.id,
        entityId: entity.entityId,
        entityType: entity.entityType,
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

  void _clearAllAttachments() {
    setState(() {
      _attachments.clear();
      _deletedAttachments.clear();
    });
    _scheduleDraftSave();
  }

  void _cancelBanner() {
    setState(() {
      if (_editingMessageId != null && _attachments.any((a) => a.id != null)) {
        _attachments.removeWhere((att) => att.id != null);

        _deletedAttachments.clear();
      }
      _editingMessageId = null;
      _answerMessage = null;
    });
    _textController.clear();
    _scheduleDraftSave();
    _unfocusInput();

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureInput());
  }

  void _onApplyEdit(Message message) {
    if (_editingMessageId == null) return;
    final entity = DeterminingContextService.getEntityKey();
    if (entity == null) return;

    final metaCurrentFiles = <MetaFileMessage>[];
    final metaNewFiles = <MetaFileMessage>[];
    final newFilesList = <File>[];

    final allAttachments = [..._attachments, ..._deletedAttachments];

    int fileIndex = 0;
    for (final att in allAttachments) {
      if (att.isNew && !att.isDeleted) {
        newFilesList.add(att.file!);
        metaNewFiles.add(
          MetaFileMessage(
            index: fileIndex,
            name: att.name,
            duration: att.duration,
            isSpoiler: att.isSpoiler,
            deleted: false,
            changed: false,
          ),
        );
        fileIndex++;
      } else if (!att.isNew) {
        metaCurrentFiles.add(
          MetaFileMessage(
            id: att.id,
            name: att.name,
            duration: att.duration,
            isSpoiler: att.isSpoiler,
            deleted: att.isDeleted,
            changed: att.isChanged && !att.isDeleted,
          ),
        );
      }
    }

    final localAttachments = convertFilesToAttachments(_attachments);

    final updatedMessage = Message(
      id: _editingMessageId,
      chatId: widget.chat.id,
      text: message.text,
      attachments: localAttachments,
      metaCurrentFilesMessage: metaCurrentFiles.isEmpty
          ? null
          : metaCurrentFiles,
      metaNewFilesMessage: metaNewFiles.isEmpty ? null : metaNewFiles,
      newFiles: newFilesList.isEmpty ? null : newFilesList,
    );

    _messageBloc.add(
      UpdateMessage(
        chatId: widget.chat.id,
        entityId: entity.entityId,
        entityType: entity.entityType,
        message: updatedMessage,
      ),
    );

    _clearAllAttachments();

    _cancelBanner();
  }

  void _onDeleteMessage(Message message) {
    final entity = DeterminingContextService.getEntityKey();
    if (entity == null) return;
    _messageBloc.add(
      DeleteMessage(
        chatId: widget.chat.id,
        entityId: entity.entityId,
        entityType: entity.entityType,
        messageId: message.id,
        localGeneratedId: message.localGeneratedId,
      ),
    );
  }

  void _onAnswerMessage(Message message) {
    if (_isExtraPanelOpen) {
      _toggleExtraPanel();
    }

    setState(() {
      _editingMessageId = null;
      _answerMessage = message;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusInput();
      _measureInput();
    });
    _scheduleDraftSave();
  }
}

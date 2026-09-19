// lib/presentation/features/chat/chat_screen.dart
import 'dart:io';
import 'dart:ui';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/enums/file_content_type.dart';
import 'package:disalive/domain/enums/file_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ui/chat_attachment.dart';
import 'package:disalive/domain/models/ui/meta_file_message.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat/widgets/chat_header.dart';
import 'package:disalive/presentation/features/chat/widgets/chat_input_area.dart';
import 'package:disalive/presentation/features/chat/widgets/messages_list.dart';
import 'package:disalive/presentation/features/chat_server/bloc/chat_server_bloc.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/profile/determinant_profile_screen.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/utils/id_generator.dart';
import 'package:disalive/presentation/utils/ui/util_file.dart';
import 'package:disalive/presentation/widgets/media_picker_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p show basename, extension;

/// Отступ для плавающих хэдера/поля ввода от краёв карточки чата.
const double _kFloatingPanelMargin = 8;

/// Начальный (минимальный) резерв под поле ввода снизу списка.
const double _kInputReserveMin = 76;

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  static Future<void> open(BuildContext context, Chat chat, bool isReconnect) {
    ChatBloc chatBloc = context.read<ChatBloc>();
    MessageBloc messageBloc = context.read<MessageBloc>();
    ChatServerBloc chatServerBloc = context.read<ChatServerBloc>();
    MembersBloc membersBloc = context.read<MembersBloc>();
    sl<ChatRepository>().setCurrentChat(chat);
    return SwipeToDismissRoute.push(
      context,
      (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: chatBloc),
          BlocProvider.value(value: messageBloc),
          BlocProvider.value(value: chatServerBloc),
          BlocProvider.value(value: membersBloc),
        ],
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
  final ValueNotifier<bool> _hasNeedSend = ValueNotifier(false);
  final FocusNode _inputFocusNode = FocusNode();
  List<ChatAttachment> _attachments = [];
  List<ChatAttachment> _deletedAttachments = [];
  int? _editingMessageId;
  Message? _answerMessage;
  bool isReconnect = false;

  late final MessageBloc _messageBloc;
  late final ChatBloc _chatBloc;

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

    _messageBloc = context.read<MessageBloc>();
    _chatBloc = context.read<ChatBloc>();
    _loadInitial();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureInput());
  }

  void _onTextChanged() {
    _onChangedNeedSend();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureInput());
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
    _hasNeedSend.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ChatBloc, ChatState>(
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
                      child: RepaintBoundary(
                        child: MessagesList(
                          key: _messagesListKey,
                          messageBloc: _messageBloc,
                          chatBloc: _chatBloc,
                          chat: _currentChat,
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
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ChatHeader(
                        chat: _currentChat,
                        isReconnect: isReconnect,
                        onTap: () => DeterminantProfileScreen.open(
                          context,
                          chat: widget.chat,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ChatInputArea(
                        key: const ValueKey('chat_input_area'),
                        chat: _currentChat,
                        inputKey: _inputKey,
                        textController: _textController,
                        hasEdit: _hasEdit,
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
                          });

                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _measureInput(),
                          );
                        },
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
    var localGeneratedId = message.localGeneratedId ?? IdGenerator.generateId();

    final metaNewFiles = <MetaFileMessage>[];
    final newFilesList = <File>[];

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

    final localAttachments = convertFilesToAttachments(_attachments);

    final localMessage = Message(
      localGeneratedId: localGeneratedId,
      chatId: widget.chat.id,
      userId: _currentUserId,
      text: message.text,
      time: DateTime.now().toUtc().toString(),
      answerMessageId: _answerMessage?.getId,
      answerMessage: _answerMessage,
      attachments: localAttachments.isEmpty ? null : localAttachments,
      newFiles: newFilesList.isEmpty ? null : newFilesList,
      metaNewFilesMessage: metaNewFiles.isEmpty ? null : metaNewFiles,
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

    if (_answerMessage != null || _attachments.isNotEmpty) {
      _cancelBanner();
    }

    _clearAllAttachments();

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
  }

  void _clearAllAttachments() {
    setState(() {
      _attachments.clear();
      _deletedAttachments.clear();
    });
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
    _unfocusInput();

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureInput());
  }

  void _onApplyEdit(Message message) {
    if (_editingMessageId == null) return;

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
        entityId: widget.chat.id,
        entityType: EntityType.chat,
        message: updatedMessage,
      ),
    );

    _clearAllAttachments();

    _cancelBanner();
  }

  void _onDeleteMessage(Message message) {
    _messageBloc.add(
      DeleteMessage(
        chatId: widget.chat.id,
        entityId: widget.chat.id,
        entityType: EntityType.chat,
        messageId: message.id,
        localGeneratedId: message.localGeneratedId,
      ),
    );
  }

  void _onAnswerMessage(Message message) {
    setState(() {
      _editingMessageId = null;
      _answerMessage = message;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusInput();
      _measureInput();
    });
  }
}

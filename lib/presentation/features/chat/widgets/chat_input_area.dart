import 'dart:io';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ui/chat_attachment.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/presentation/features/chat/channel_mention.dart';
import 'package:disalive/presentation/features/chat/user_mention.dart';
import 'package:disalive/presentation/utils/ui/emoji_text_parser.dart';
import 'package:disalive/presentation/features/chat/widgets/attachments/attachment_container.dart';
import 'package:disalive/presentation/features/chat/widgets/banners/input_banner_top.dart';
import 'package:disalive/presentation/features/chat/widgets/voice/voice_record_overlay.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:disalive/presentation/widgets/emoji_text_editing_controller.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

const double _kFloatingPanelMargin = 8;

class ChatInputArea extends StatefulWidget {
  final Chat chat;
  final int? serverId;
  final bool isReconnect;
  final bool canSendMessages;
  final FocusNode inputFocusNode;
  final GlobalKey inputKey;
  final bool hasEdit;
  final bool hasAnswer;
  final Message? answerMessage;
  final ValueNotifier<bool> hasNeedSend;
  final TextEditingController textController;
  final VoidCallback cancelBanner;
  final Function(Message message) onSendMessage;
  final Function(Message message) onApplyEdit;
  final List<ChatAttachment> attachments;
  final VoidCallback onPickAttachment;
  final Function(ChatAttachment) onRemoveAttachment;
  final Function(ChatAttachment) onUpdateAttachment;
  final Function(File file, double durationSeconds) onSendVoiceMessage;
  final Function() onToggleExtraPanel;
  final Function() onHideKeyboard;
  final bool isExtraPanelOpen;

  const ChatInputArea({
    super.key,
    required this.chat,
    this.serverId,
    required this.isReconnect,
    this.canSendMessages = true,
    required this.inputKey,
    required this.textController,
    required this.hasEdit,
    required this.hasAnswer,
    required this.answerMessage,
    required this.hasNeedSend,
    required this.cancelBanner,
    required this.onSendMessage,
    required this.onApplyEdit,
    required this.inputFocusNode,
    required this.attachments,
    required this.onPickAttachment,
    required this.onRemoveAttachment,
    required this.onUpdateAttachment,
    required this.onSendVoiceMessage,
    required this.onToggleExtraPanel,
    required this.onHideKeyboard,
    required this.isExtraPanelOpen,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  // 🎯 Ключ для прямого вызова методов внутри VoiceRecordOverlay
  final GlobalKey<VoiceRecordOverlayState> _voiceRecorderKey = GlobalKey();
  final GlobalKey _micButtonKey = GlobalKey();
  OverlayEntry? _voiceOverlayEntry;
  ChannelMentionQuery? _mentionQuery;
  UserMentionQuery? _userMentionQuery;
  bool _loadingChannels = false;
  List<Member> _mentionMembers = const [];
  EntityKey? _loadedMembersKey;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_updateMentionQuery);
  }

  @override
  void didUpdateWidget(covariant ChatInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textController != widget.textController) {
      oldWidget.textController.removeListener(_updateMentionQuery);
      widget.textController.addListener(_updateMentionQuery);
    }
    if (oldWidget.serverId != widget.serverId ||
        oldWidget.chat.id != widget.chat.id ||
        oldWidget.canSendMessages != widget.canSendMessages) {
      _loadedMembersKey = null;
      _mentionMembers = const [];
      _updateMentionQuery();
      if (_userMentionQuery != null) _loadMentionMembers();
    }
  }

  void _updateMentionQuery() {
    final userQuery = widget.canSendMessages
        ? UserMention.queryAtCaret(widget.textController.value)
        : null;
    final query = widget.serverId == null || !widget.canSendMessages
        ? null
        : ChannelMention.queryAtCaret(widget.textController.value);
    if (query?.start == _mentionQuery?.start &&
        query?.end == _mentionQuery?.end &&
        query?.text == _mentionQuery?.text &&
        userQuery?.start == _userMentionQuery?.start &&
        userQuery?.end == _userMentionQuery?.end &&
        userQuery?.text == _userMentionQuery?.text) {
      return;
    }
    setState(() {
      _mentionQuery = query;
      _userMentionQuery = userQuery;
    });
    if (userQuery != null) _loadMentionMembers();
    final serverId = widget.serverId;
    if (query != null &&
        serverId != null &&
        !_loadingChannels &&
        sl<ChannelServerRepository>().getCached(serverId).isEmpty) {
      _loadingChannels = true;
      sl<ChannelServerRepository>().get(serverId).then((_) {
        _loadingChannels = false;
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _loadMentionMembers() async {
    final entityId = widget.serverId ?? widget.chat.id;
    final key = EntityKey(
      entityId: entityId,
      entityType: widget.serverId == null ? EntityType.chat : EntityType.server,
    );
    if (_loadedMembersKey == key) return;
    _loadedMembersKey = key;
    final repository = sl<MembersRepository>();
    var members = await repository.getCached(key);
    if (members.isEmpty || members.every((member) => member.user == null)) {
      final result = await repository.get(key.entityId, key.entityType);
      result.fold((_) {
        if (_loadedMembersKey == key) _loadedMembersKey = null;
      }, (loaded) => members = loaded);
    }
    if (!mounted || _loadedMembersKey != key) return;
    setState(() => _mentionMembers = members);
  }

  void _insertUser(Member member) {
    final query = _userMentionQuery;
    final user = member.user;
    if (query == null || user == null) return;
    widget.textController.value = UserMention.insert(
      widget.textController.value,
      query,
      user,
    );
    widget.inputFocusNode.requestFocus();
  }

  void _insertChannel(ChannelServer channel) {
    final query = _mentionQuery;
    if (query == null) return;
    widget.textController.value = ChannelMention.insert(
      widget.textController.value,
      query,
      channel,
    );
    widget.inputFocusNode.requestFocus();
  }

  bool get _isRecording => _voiceOverlayEntry != null;

  bool get _hasBanner => widget.hasEdit || widget.hasAnswer;

  @override
  void dispose() {
    widget.textController.removeListener(_updateMentionQuery);
    _removeVoiceOverlay();
    super.dispose();
  }

  void _showVoiceRecorder() async {
    widget.onHideKeyboard();

    if (_voiceOverlayEntry != null) return;

    _voiceOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          const Positioned.fill(child: AbsorbPointer(absorbing: true)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VoiceRecordOverlay(
              key: _voiceRecorderKey,
              onSend: (data) {
                _removeVoiceOverlay();
                widget.onSendVoiceMessage(data.file, data.durationSeconds);
              },
              onCancel: _removeVoiceOverlay,
              onLock: (isLocked) {},
            ),
          ),
        ],
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_voiceOverlayEntry!);

    // 🎯 3. ЖДЁМ, ПОКА ИНТЕРФЕЙС НАЧНЁТ СДВИГАТЬСЯ ПОСЛЕ СКРЫТИЯ КЛАВИАТУРЫ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Небольшая задержка гарантирует, что RenderBox кнопки уже обновил свои координаты
      Future.delayed(const Duration(milliseconds: 1500), () {
        final micBox =
            _micButtonKey.currentContext?.findRenderObject() as RenderBox?;

        if (micBox != null && _voiceRecorderKey.currentState != null) {
          // Получаем ЦЕНТР кнопки микрофона в новых глобальных координатах
          final centerPosition = micBox.localToGlobal(
            Offset(micBox.size.width / 2, micBox.size.height / 2),
          );

          _voiceRecorderKey.currentState!.startDrag(centerPosition);
        }
      });
    });
  }

  Widget _buildChannelSuggestions(int serverId, ChannelMentionQuery query) {
    final channels = sl<ChannelServerRepository>()
        .getCached(serverId)
        .where(
          (channel) =>
              channel.chatId != null &&
              (channel.chatName ?? '').toLowerCase().contains(
                query.text.toLowerCase(),
              ),
        )
        .take(6)
        .toList();
    if (channels.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      constraints: const BoxConstraints(maxHeight: 224),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 5),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          return CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            onPressed: () => _insertChannel(channel),
            child: Row(
              children: [
                Icon(
                  channel.type == 'voice'
                      ? CupertinoIcons.speaker_2_fill
                      : CupertinoIcons.number,
                  size: 18,
                  color: AppColors.greyple,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: EmojiTextParser.parse(
                        channel.chatName ?? 'Канал',
                        emojiSize: 18,
                        animateEmoji: false,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.mediumTextStyle.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserSuggestions(UserMentionQuery query) {
    final members = _mentionMembers
        .where((member) {
          final username = member.user?.username;
          return username != null &&
              username.toLowerCase().contains(query.text.toLowerCase());
        })
        .take(6)
        .toList();
    if (members.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      constraints: const BoxConstraints(maxHeight: 224),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 5),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          final user = member.user!;
          return CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            onPressed: () => _insertUser(member),
            child: Row(
              children: [
                BuildAvatar(url: user.urlAvatar, wh: 28, size: 14),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${user.getDisplayName}  @${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.mediumTextStyle.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _removeVoiceOverlay() {
    if (_voiceOverlayEntry != null) {
      _voiceOverlayEntry!.remove();
      _voiceOverlayEntry = null;
    }
  }

  BorderRadiusGeometry get _getRadiusForButton => BorderRadius.only(
    topLeft: Radius.circular(_hasBanner ? 12 : 36),
    topRight: Radius.circular(_hasBanner ? 12 : 36),
    bottomLeft: const Radius.circular(36),
    bottomRight: const Radius.circular(36),
  );

  @override
  Widget build(BuildContext context) {
    final bool isInputAllowed =
        !widget.chat.isAnyBlocked &&
        !widget.isReconnect &&
        widget.canSendMessages;

    return Padding(
      key: widget.inputKey,
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
          if (widget.hasEdit) _buildEditBanner(),
          if (widget.hasAnswer) _buildAnswerBanner(widget.answerMessage),
          if (_hasBanner) const SizedBox(height: 6),
          if (widget.attachments.isNotEmpty)
            AttachmentContainer(
              attachments: widget.attachments,
              hasBanner: _hasBanner,
              onRemove: widget.onRemoveAttachment,
              onUpdate: widget.onUpdateAttachment,
            ),
          if (_mentionQuery != null && widget.serverId != null)
            _buildChannelSuggestions(widget.serverId!, _mentionQuery!),
          if (_userMentionQuery != null)
            _buildUserSuggestions(_userMentionQuery!),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isInputAllowed) ...[
                GlassIconButton(
                  icon: CupertinoIcons.add,
                  onTap: widget.onPickAttachment,
                  size: 36,
                  borderRadius: _getRadiusForButton,
                  hasBorderRadius: true,
                ),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(_hasBanner ? 8 : 20),
                    topRight: Radius.circular(_hasBanner ? 8 : 20),
                    bottomLeft: const Radius.circular(20),
                    bottomRight: const Radius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_hasBanner ? 8 : 20),
                        topRight: Radius.circular(_hasBanner ? 8 : 20),
                        bottomLeft: const Radius.circular(20),
                        bottomRight: const Radius.circular(20),
                      ),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: !widget.canSendMessages && !widget.isReconnect
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Text(
                              'У вас недостаточно прав, чтобы отправлять сообщения на этом канале',
                              style: AppText.mediumTextStyle.copyWith(
                                color: AppColors.greyple,
                              ),
                            ),
                          )
                        : CupertinoTextField(
                            controller: widget.textController,
                            inputFormatters: const [
                              EmojiAtomicDeletionFormatter(),
                            ],
                            focusNode: widget.inputFocusNode,
                            readOnly: !isInputAllowed,
                            minLines: 1,
                            maxLines: 5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            placeholder: isInputAllowed
                                ? 'Сообщение...'
                                : getRestrictionMessage(),
                            placeholderStyle: AppText.mediumTextStyle.copyWith(
                              color: AppColors.greyple,
                            ),
                            style: AppText.mediumTextStyle.copyWith(
                              color: widget.chat.isAnyBlocked
                                  ? AppColors.white.withValues(alpha: 0.7)
                                  : AppColors.white,
                            ),
                            decoration: null,
                          ),
                  ),
                ),
              ),
              if (isInputAllowed) ...[
                const SizedBox(width: 5),
                !widget.isExtraPanelOpen
                    ? GlassIconButton(
                        icon: CupertinoIcons.smiley,
                        onTap: widget.onToggleExtraPanel,
                        borderRadius: _getRadiusForButton,
                        hasBorderRadius: true,
                      )
                    : GlassIconButton(
                        icon: CupertinoIcons.keyboard,
                        onTap: widget.onToggleExtraPanel,
                        borderRadius: _getRadiusForButton,
                        hasBorderRadius: true,
                      ),

                const SizedBox(width: 5),
                // 🎯 GestureDetector теперь управляет всем циклом записи
                GestureDetector(
                  key: _micButtonKey,
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final message = Message(
                      text: widget.textController.value.text,
                    );
                    if (widget.hasEdit) {
                      widget.onApplyEdit(message);
                    } else if (widget.hasNeedSend.value) {
                      widget.onSendMessage(message);
                    }
                    widget.textController.clear();
                  },
                  onLongPressStart: (details) {
                    if (!widget.hasEdit && !widget.hasNeedSend.value) {
                      _showVoiceRecorder();
                    }
                  },
                  onLongPressMoveUpdate: (details) {
                    if (_isRecording) {
                      _voiceRecorderKey.currentState?.updateDrag(
                        details.globalPosition,
                      );
                    }
                  },
                  onLongPressEnd: (details) {
                    if (_isRecording) {
                      _voiceRecorderKey.currentState?.endDrag();
                    }
                  },
                  onLongPressCancel: () {
                    if (_isRecording) {
                      _voiceRecorderKey.currentState?.cancelDrag();
                    }
                  },
                  child: ValueListenableBuilder<bool>(
                    valueListenable: widget.hasNeedSend,
                    builder: (context, hasText, _) {
                      return GlassIconButton(
                        icon: widget.hasEdit
                            ? CupertinoIcons.checkmark_alt
                            : hasText
                            ? CupertinoIcons.arrow_up
                            : CupertinoIcons.mic_solid,
                        filled: hasText || widget.hasEdit,
                        onTap: () {
                          final message = Message(
                            text: widget.textController.value.text,
                          );
                          if (widget.hasEdit) {
                            widget.onApplyEdit(message);
                          } else if (hasText) {
                            widget.onSendMessage(message);
                          }
                          widget.textController.clear();
                        },
                        size: 36,
                        borderRadius: _getRadiusForButton,
                        hasBorderRadius: true,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditBanner() {
    return InputBannerTop(
      title: 'Редактирование сообщения',
      icon: CupertinoIcons.pencil,
      onClose: widget.cancelBanner,
    );
  }

  Widget _buildAnswerBanner(Message? message) {
    if (message?.user == null) {
      return const SizedBox.shrink();
    }

    return InputBannerTop(
      title: 'Ответ ${message!.user!.displayName ?? ''}',
      icon: CupertinoIcons.arrow_turn_up_left,
      onClose: widget.cancelBanner,
    );
  }

  String? getRestrictionMessage() {
    String? displayName = widget.chat.user?.displayName;

    if (widget.isReconnect) {
      return "Соединение с сервером...";
    }
    if (widget.chat.user?.onlyIBlocked == true) {
      return 'Вы заблокировали пользователя $displayName';
    }
    if (widget.chat.user?.onlyTheyBlocked == true) {
      return 'Вас заблокировал пользователь $displayName';
    }
    if (widget.chat.user?.bothBlocked == true) {
      return 'Вы и пользователь $displayName заблокировали друг друга';
    }

    return null;
  }
}

import 'dart:io';
import 'dart:ui';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ui/chat_attachment.dart';
import 'package:disalive/presentation/features/chat/widgets/attachments/attachment_container.dart';
import 'package:disalive/presentation/features/chat/widgets/banners/input_banner_top.dart';
import 'package:disalive/presentation/features/chat/widgets/voice/voice_record_overlay.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';

const double _kFloatingPanelMargin = 8;

class ChatInputArea extends StatefulWidget {
  final Chat chat;
  final bool isReconnect;
  final FocusNode inputFocusNode;
  final GlobalKey inputKey;
  final bool hasEdit;
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

  const ChatInputArea({
    super.key,
    required this.chat,
    required this.isReconnect,
    required this.inputKey,
    required this.textController,
    required this.hasEdit,
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
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  // 🎯 Ключ для прямого вызова методов внутри VoiceRecordOverlay
  final GlobalKey<VoiceRecordOverlayState> _voiceRecorderKey = GlobalKey();
  OverlayEntry? _voiceOverlayEntry;

  bool get _isRecording => _voiceOverlayEntry != null;

  @override
  void dispose() {
    _removeVoiceOverlay();
    super.dispose();
  }

  void _showVoiceRecorder(Offset initialGlobalPosition) {
    if (_voiceOverlayEntry != null) return;

    _voiceOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Блокирует тапы по всему, что под оверлеем, пока идёт запись —
          // раньше это пытался делать локальный Positioned.fill внутри
          // Column инпут-бара, что не работало (Positioned требует Stack).
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
              onLock: (isLocked) {
                // Тактильный отклик можно добавить здесь
              },
            ),
          ),
        ],
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_voiceOverlayEntry!);
    // Небольшая задержка, чтобы виджет успел отрисоваться перед первым вызовом
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _voiceRecorderKey.currentState?.startDrag(initialGlobalPosition);
    });
  }

  void _removeVoiceOverlay() {
    if (_voiceOverlayEntry != null) {
      _voiceOverlayEntry!.remove();
      _voiceOverlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasAnswer = widget.answerMessage != null;
    final bool isInputAllowed =
        !widget.chat.isAnyBlocked && !widget.isReconnect;

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
          if (hasAnswer) _buildAnswerBanner(widget.answerMessage),
          if (widget.hasEdit || hasAnswer) const SizedBox(height: 6),
          if (widget.attachments.isNotEmpty)
            AttachmentContainer(
              attachments: widget.attachments,
              hasBanner: widget.hasEdit || hasAnswer,
              onRemove: widget.onRemoveAttachment,
              onUpdate: widget.onUpdateAttachment,
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isInputAllowed) ...[
                GlassIconButton(
                  icon: CupertinoIcons.add,
                  onTap: widget.onPickAttachment,
                  size: 36,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(widget.hasEdit ? 8 : 20),
                    topRight: Radius.circular(widget.hasEdit ? 8 : 20),
                    bottomLeft: const Radius.circular(20),
                    bottomRight: const Radius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(widget.hasEdit ? 8 : 20),
                        topRight: Radius.circular(widget.hasEdit ? 8 : 20),
                        bottomLeft: const Radius.circular(20),
                        bottomRight: const Radius.circular(20),
                      ),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: CupertinoTextField(
                      controller: widget.textController,
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
                const SizedBox(width: 10),
                // 🎯 GestureDetector теперь управляет всем циклом записи
                GestureDetector(
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
                      _showVoiceRecorder(details.globalPosition);
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

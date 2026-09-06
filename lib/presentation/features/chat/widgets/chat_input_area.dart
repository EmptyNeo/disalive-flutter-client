import 'dart:ui';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/presentation/features/chat/widgets/banners/input_banner_top.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const double _kFloatingPanelMargin = 8;

class ChatInputArea extends StatelessWidget {
  final FocusNode _inputFocusNode;
  final GlobalKey _inputKey;
  final bool _hasEdit;
  final Message? _answerMessage;
  final ValueNotifier<bool> _hasText;
  final TextEditingController _textController;
  final VoidCallback _cancelBanner;
  final Function(Message message) _onSendMessage;
  final Function(Message message) _onApplyEdit;

  const ChatInputArea({
    super.key,
    required GlobalKey inputKey,
    required TextEditingController textController,
    required bool hasEdit,
    required Message? answerMessage,
    required ValueNotifier<bool> hasText,
    required VoidCallback cancelBanner,
    required Function(Message message) onSendMessage,
    required Function(Message message) onApplyEdit,
    required FocusNode inputFocusNode,
  }) : _inputKey = inputKey,
       _textController = textController,
       _hasEdit = hasEdit,
       _answerMessage = answerMessage,
       _hasText = hasText,
       _cancelBanner = cancelBanner,
       _onSendMessage = onSendMessage,
       _onApplyEdit = onApplyEdit,
       _inputFocusNode = inputFocusNode;

  @override
  Widget build(BuildContext context) {
    bool hasAnswer = _answerMessage != null;

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
          if (hasAnswer) _buildAnswerBanner(_answerMessage),
          if (_hasEdit || hasAnswer) const SizedBox(height: 6),
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
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
                      focusNode: _inputFocusNode,
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
                        _onApplyEdit(message);
                      } else if (hasText) {
                        _onSendMessage(message);
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
    return InputBannerTop(
      title: 'Редактирование сообщения',
      icon: CupertinoIcons.pencil,
      onClose: _cancelBanner,
    );
  }

  Widget _buildAnswerBanner(Message message) {
    final user = message.user;
    if (user == null) {
      return SizedBox.shrink();
    }

    return InputBannerTop(
      title: 'Ответ ${_answerMessage?.user?.displayName ?? ''}',
      icon: CupertinoIcons.arrow_turn_up_left,
      onClose: _cancelBanner,
    );
  }
}

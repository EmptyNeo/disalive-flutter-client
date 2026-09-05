import 'dart:ui';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const double _kFloatingPanelMargin = 8;

class ChatInputArea extends StatelessWidget {
  final FocusNode _inputFocusNode;
  final GlobalKey _inputKey;
  final bool _hasEdit;
  final ValueNotifier<bool> _hasText;
  final TextEditingController _textController;
  final VoidCallback _cancelEdit;
  final Function(Message message) _onSendMessage;
  final Function(Message message) _onApplyEdit;

  const ChatInputArea({
    super.key,
    required GlobalKey inputKey,
    required TextEditingController textController,
    required bool hasEdit,
    required ValueNotifier<bool> hasText,
    required VoidCallback cancelEdit,
    required Function(Message message) onSendMessage,
    required Function(Message message) onApplyEdit,
    required FocusNode inputFocusNode,
  }) : _inputKey = inputKey,
       _textController = textController,
       _hasEdit = hasEdit,
       _hasText = hasText,
       _cancelEdit = cancelEdit,
       _onSendMessage = onSendMessage,
       _onApplyEdit = onApplyEdit,
       _inputFocusNode = inputFocusNode;

  @override
  Widget build(BuildContext context) {
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
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
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
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
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
              CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.blurple,
                child: Icon(
                  CupertinoIcons.pencil,
                  size: 14,
                  color: AppColors.onBlurple,
                ),
              ),
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
}

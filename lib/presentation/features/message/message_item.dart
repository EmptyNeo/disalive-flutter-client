// lib/presentation/features/message/message_item.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/ui/message_tail_direction.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/presentation/features/message/widgets/forward_message_preview.dart';
import 'package:disalive/presentation/utils/util_date.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

class MessageItem extends StatelessWidget {
  const MessageItem({
    super.key,
    required this.message,
    required this.isMine,
    this.showSender = false,
    this.onLongPress,
    this.onTap,
    this.showTime = true,
    this.tailDirection = MessageTailDirection.none,
    this.showAvatar = true,
    this.backgroundMessage,
  });

  final Message message;
  final bool isMine;
  final bool showSender;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final bool showTime;
  final MessageTailDirection tailDirection;
  final bool showAvatar;
  final Color? backgroundMessage;

  @override
  Widget build(BuildContext context) {
    final hasLinkPreview = message.linkPreview != null;
    final hasInviteData = message.inviteData != null;
    final hasAttachments = message.attachments?.isNotEmpty ?? false;
    final hasReactions = message.reactions?.isNotEmpty ?? false;
    final hasAnswer = message.answerMessage != null;
    final hasForward = message.forwardMessage != null;
    final showSenderInfo = !isMine && showSender && showAvatar;
    var backgroundColor = isMine
        ? AppColors.blurple
        : AppColors.glassPanelBottom;
    if (backgroundMessage != null) {
      backgroundColor = backgroundMessage as Color;
    }

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Row(
          mainAxisAlignment: isMine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showSenderInfo) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: BuildAvatar(
                  url: message.user?.pathImage,
                  wh: 26,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
            ],
            // Если аватар не показываем, но это групповой чат —
            // добавляем отступ для идеального выравнивания по вертикали
            if (!isMine && showSender && !showAvatar) ...[
              const SizedBox(width: 26 + 6),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                  minWidth: 50,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: _buildBorderRadius(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showSenderInfo && message.user != null) ...[
                      Text(
                        message.user!.displayName ?? 'Пользователь',
                        style: AppText.lowTextStyle.copyWith(
                          color: AppColors.blurple,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],

                    if (hasForward && message.forwardMessage != null) ...[
                      ForwardedMessagePreview(message: message),
                    ],

                    if (hasAnswer) _stubLine('Ответ на сообщение'),

                    if ((message.text ?? '').isNotEmpty)
                      Text(
                        message.text!,
                        style: AppText.mediumTextStyle.copyWith(
                          color: isMine ? AppColors.onBlurple : AppColors.white,
                        ),
                      ),

                    if (hasLinkPreview) _stubLine('Превью ссылки'),
                    if (hasInviteData) _stubLine('Приглашение'),
                    if (hasAttachments) _stubLine('Вложения'),
                    if (hasReactions) _stubLine('Реакции'),

                    if (showTime) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            UtilDate.formatTime(message.time),
                            style: AppText.lowTextStyle.copyWith(
                              color: AppColors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BorderRadius _buildBorderRadius() {
    final double smallRadius = 4;
    final double bigRadius = 14;
    final double squareRadius = 8;

    if (tailDirection == MessageTailDirection.none) {
      return BorderRadius.circular(squareRadius);
    }

    if (isMine) {
      if (tailDirection == MessageTailDirection.down) {
        return BorderRadius.only(
          topLeft: Radius.circular(bigRadius),
          topRight: Radius.circular(bigRadius),
          bottomLeft: Radius.circular(bigRadius),
          bottomRight: Radius.circular(smallRadius),
        );
      } else {
        return BorderRadius.only(
          topLeft: Radius.circular(bigRadius),
          topRight: Radius.circular(smallRadius),
          bottomLeft: Radius.circular(bigRadius),
          bottomRight: Radius.circular(bigRadius),
        );
      }
    } else {
      if (tailDirection == MessageTailDirection.down) {
        return BorderRadius.only(
          topLeft: Radius.circular(bigRadius),
          topRight: Radius.circular(bigRadius),
          bottomLeft: Radius.circular(smallRadius),
          bottomRight: Radius.circular(bigRadius),
        );
      } else {
        return BorderRadius.only(
          topLeft: Radius.circular(smallRadius),
          topRight: Radius.circular(bigRadius),
          bottomLeft: Radius.circular(bigRadius),
          bottomRight: Radius.circular(bigRadius),
        );
      }
    }
  }

  Widget _stubLine(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '[в разработке] $label',
        style: AppText.lowTextStyle.copyWith(
          color: AppColors.greyple,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

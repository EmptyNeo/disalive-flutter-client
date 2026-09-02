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
    this.hasMessageAbove = false,
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
  final bool hasMessageAbove;
  final Color? backgroundMessage;

  @override
  Widget build(BuildContext context) {
    final hasForward = message.forwardMessage != null;
    // Пересланное сообщение заменяет контент бабла целиком — текст,
    // вложения, ссылка и приглашение берутся из оригинала. Реакции и время
    // остаются от message: это метаданные конкретно этого экземпляра
    // сообщения в текущем чате, а не оригинала.
    final Message contentMessage = hasForward
        ? message.forwardMessage!
        : message;

    final hasLinkPreview = contentMessage.linkPreview != null;
    final hasInviteData = contentMessage.inviteData != null;
    final hasAttachments = contentMessage.attachments?.isNotEmpty ?? false;
    final hasReactions = message.reactions?.isNotEmpty ?? false;
    final hasAnswer = message.answerMessage != null;
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
          crossAxisAlignment: showSenderInfo
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (showSenderInfo) ...[
              BuildAvatar(url: message.user?.pathImage, wh: 26, size: 16),
              const SizedBox(width: 6),
            ],
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

                    if (hasForward) ...[
                      Row(
                        children: [
                          BuildAvatar(
                            url: message.forwardMessage?.user?.pathImage,
                            wh: 16,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Переслано от ${message.forwardMessage?.user?.displayName ?? 'Пользователь'}',
                              style: AppText.lowTextStyle.copyWith(
                                color: isMine
                                    ? AppColors.onBlurple.withValues(
                                        alpha: 0.85,
                                      )
                                    : AppColors.linkBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    if (hasAnswer) _stubLine('Ответ на сообщение'),

                    if ((contentMessage.text ?? '').isNotEmpty)
                      Text(
                        contentMessage.text!,
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
                              color: isMine
                                  ? AppColors.onBlurple.withValues(alpha: 0.7)
                                  : AppColors.greyple,
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
    final Radius small = const Radius.circular(4); // Обычный хвостик
    final Radius big = const Radius.circular(14); // Скругленный угол
    final Radius square = const Radius.circular(8); // Плоский стык
    final Radius pronounced =
        Radius.zero; // Острый хвостик, тянущийся к аватару

    // Проверяем, что это чужое сообщение именно в групповом чате
    final bool isOtherInGroup = !isMine && showSender;

    if (isOtherInGroup) {
      // --- ЛОГИКА ДЛЯ ГРУППОВЫХ ЧАТОВ (Telegram-стиль) ---
      if (tailDirection == MessageTailDirection.none) {
        // Среднее сообщение: левая сторона плоская, правая круглая
        return BorderRadius.only(
          topLeft: square,
          bottomLeft: square,
          topRight: big,
          bottomRight: big,
        );
      } else {
        // tailDirection == MessageTailDirection.down (Первое, Последнее или Единственное)
        return BorderRadius.only(
          topRight: big,
          bottomRight: big,
          // Если есть сообщение выше (Последнее) — делаем стык. Иначе (Первое/Единственное) — круглый верх без стыков
          topLeft: hasMessageAbove ? square : big,
          // Если есть аватар (Последнее/Единственное) — тянем острый хвост к нему. Иначе (Первое) — обычный хвост вниз
          bottomLeft: showAvatar ? pronounced : small,
        );
      }
    } else {
      // --- СТРОГАЯ ЛОГИКА ДЛЯ МОИХ (isMine) И ЛИЧНЫХ ЧАТОВ ---
      if (tailDirection == MessageTailDirection.none) {
        return BorderRadius.only(
          topLeft: isMine ? big : square,
          bottomLeft: isMine ? big : square,
          topRight: isMine ? square : big,
          bottomRight: isMine ? square : big,
        );
      }

      if (isMine) {
        if (tailDirection == MessageTailDirection.up) {
          return BorderRadius.only(
            topLeft: big,
            bottomLeft: big,
            topRight: small,
            bottomRight: big,
          );
        } else {
          return BorderRadius.only(
            topLeft: big,
            bottomLeft: big,
            topRight: hasMessageAbove ? square : big,
            bottomRight: small,
          );
        }
      } else {
        if (tailDirection == MessageTailDirection.up) {
          return BorderRadius.only(
            topRight: big,
            bottomRight: big,
            topLeft: small,
            bottomLeft: big,
          );
        } else {
          return BorderRadius.only(
            topRight: big,
            bottomRight: big,
            topLeft: hasMessageAbove ? square : big,
            bottomLeft: small,
          );
        }
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

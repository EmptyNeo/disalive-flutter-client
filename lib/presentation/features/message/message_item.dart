// lib/presentation/features/message/message_item.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/ui/message_tail_direction.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/presentation/features/message/widgets/answer_preview.dart';
import 'package:disalive/presentation/features/message/widgets/link_preview.dart';
import 'package:disalive/presentation/features/message/widgets/media/medias_grid.dart';
import 'package:disalive/presentation/features/message/widgets/message_status_row.dart';
import 'package:disalive/presentation/features/profile/user_profile_screen.dart';
import 'package:disalive/presentation/utils/ui/util_date.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

class MessageItem extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool isRead;
  final bool showSender;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final bool showTime;
  final MessageTailDirection tailDirection;
  final bool showAvatar;
  final bool hasMessageAbove;
  final Color? backgroundMessage;
  final ActionType? isLoading;
  final bool hasError;
  final bool isHighlighted;

  final void Function(int? messageId)? onNavigateToMessage;
  final void Function(int attachmentIndex)? onTapImage;

  bool get hasLoading => isLoading != null;

  const MessageItem({
    super.key,
    required this.message,
    required this.isMine,
    required this.isRead,
    this.showSender = false,
    this.onLongPress,
    this.onTap,
    this.showTime = true,
    this.tailDirection = MessageTailDirection.none,
    this.showAvatar = true,
    this.hasMessageAbove = false,
    this.backgroundMessage,
    this.isLoading,
    this.hasError = false,
    this.isHighlighted = false,
    this.onTapImage,
    this.onNavigateToMessage,
  });

  @override
  Widget build(BuildContext context) {
    final hasForward = message.forwardMessage != null;
    final Message contentMessage = hasForward
        ? message.forwardMessage!
        : message;

    final hasLinkPreview = contentMessage.linkPreview != null;
    final hasInviteData = contentMessage.inviteData != null;
    final hasReactions = message.reactions?.isNotEmpty ?? false;
    final hasAnswer = message.answerMessage != null;
    final showSenderInfo = !isMine && showSender && showAvatar;
    final showStatusRow = isMine || showTime || hasLoading || hasError;
    final hasText = (contentMessage.text ?? '').isNotEmpty;

    final isMediasOnly =
        MediasGrid.hasOnlyImage(contentMessage) &&
        !hasText &&
        !hasLinkPreview &&
        !hasInviteData &&
        !hasReactions &&
        !hasAnswer &&
        !hasForward;

    final bool useInlineStatus =
        showStatusRow &&
        hasText &&
        !hasLinkPreview &&
        !hasInviteData &&
        !MediasGrid.hasOnlyImage(contentMessage);

    var backgroundColor = isMine ? AppColors.blurple : AppColors.actionGrey;

    if (isMediasOnly) {
      backgroundColor = CupertinoColors.transparent;
    } else if (backgroundMessage != null) {
      backgroundColor = backgroundMessage as Color;
    }

    if (isHighlighted && !isMediasOnly) {
      backgroundColor = AppColors.highlight;
    }

    final paddingLeftBubble = isMine ? 12.0 : 0.0;
    final paddingRightBubble = isMine ? 0.0 : 12.0;

    final paddingBubble = isMediasOnly
        ? EdgeInsets.only(
            left: paddingLeftBubble,
            right: paddingRightBubble,
            top: 0,
            bottom: 0,
          )
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

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
              GestureDetector(
                onTap: () {
                  UserProfileScreen.open(
                    context,
                    username: message.user?.username ?? '',
                  );
                },
                child: BuildAvatar(
                  url: message.user?.pathImage,
                  wh: 26,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (!isMine && showSender && !showAvatar) ...[
              const SizedBox(width: 26 + 6),
            ],
            Flexible(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOut,
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                  minWidth: 50,
                ),
                padding: paddingBubble,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: _buildBorderRadius(),
                ),
                child: Column(
                  crossAxisAlignment: isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
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
                        mainAxisSize: MainAxisSize.min, // 🎯 Добавляем это
                        children: [
                          BuildAvatar(
                            url: message.forwardMessage?.user?.pathImage,
                            wh: 16,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          // 🎯 УБИРАЕМ Flexible отсюда! Текст сам обрежется из-за maxLines: 1,
                          // а Row не будет растягиваться на всю ширину пузыря.
                          Text(
                            'Переслано от ${message.forwardMessage?.user?.getDisplayName}',
                            style: AppText.lowTextStyle.copyWith(
                              color: isMine
                                  ? AppColors.onBlurple.withValues(alpha: 0.85)
                                  : AppColors.linkBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    if (hasAnswer)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onNavigateToMessage?.call(
                          message.answerMessage?.id,
                        ),
                        child: AnswerPreview(
                          message: message.answerMessage,
                          isMine: isMine,
                        ),
                      ),

                    if (hasText && useInlineStatus)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Text.rich(
                            textWidthBasis: TextWidthBasis.longestLine,
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: contentMessage.text!,
                                  style: AppText.mediumTextStyle.copyWith(
                                    color: isMine
                                        ? AppColors.onBlurple
                                        : AppColors.white,
                                  ),
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: SizedBox(width: _statusReserveWidth()),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: MessageStatusRow(
                              // 🎯 Используем новый виджет
                              message: message,
                              isMine: isMine,
                              isRead: isRead,
                              showTime: showTime,
                              isLoading: isLoading,
                              hasError: hasError,
                            ),
                          ),
                        ],
                      )
                    else if (hasText)
                      Text(
                        contentMessage.text!,
                        textWidthBasis: TextWidthBasis.longestLine,
                        style: AppText.mediumTextStyle.copyWith(
                          color: isMine ? AppColors.onBlurple : AppColors.white,
                        ),
                      ),

                    if (hasLinkPreview)
                      LinkPreview(
                        link: contentMessage.linkPreview!,
                        isMine: isMine,
                      ),
                    if (hasInviteData) _stubLine('Приглашение'),

                    MediasGrid(
                      message: contentMessage,
                      isMine: isMine,
                      hasContentAbove:
                          (contentMessage.text ?? '').isNotEmpty ||
                          hasAnswer ||
                          hasForward,
                      onTapImage: onTapImage,
                      showTime: showTime,
                      isRead: isRead,
                      isLoading: isLoading,
                      hasError: hasError,
                    ),

                    if (hasReactions) _stubLine('Реакции'),

                    // 🎯 Используем новый виджет и здесь, если статус не inline
                    if (showStatusRow &&
                        !useInlineStatus &&
                        !MediasGrid.hasOnlyImage(contentMessage)) ...[
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: MessageStatusRow(
                          message: message,
                          isMine: isMine,
                          isRead: isRead,
                          showTime: showTime,
                          isLoading: isLoading,
                          hasError: hasError,
                        ),
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

  IconData getLoadingIcon() {
    switch (isLoading) {
      case null:
      case ActionType.create:
      case ActionType.update:
        return CupertinoIcons.time;
      case ActionType.delete:
        return CupertinoIcons.trash;
      case ActionType.block:
        return CupertinoIcons.lock_fill;
    }
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

  // Сколько горизонтального места "вырезать" в конце текста под время и
  // галочки, чтобы Positioned-статус в Stack не наезжал на буквы.
  //
  // Раньше ширина строки времени была захардкожена ("28"), а не измерена —
  // из-за этого резерв то не совпадал с реальным виджетом (текст с временем
  // слипались), то оказывался чуть больше (пустое место справа от статуса).
  // Теперь ширину "чч:мм" меряем тем же TextPainter'ом и тем же стилем,
  // которым он реально рисуется в _buildStatusRow(), так что резерв всегда
  // равен фактическому размеру виджета — плюс явный отступ (_kStatusGap)
  // между текстом и статусом, как в Telegram.
  static const double _kStatusGap = 6;

  double _statusReserveWidth() {
    double width = _kStatusGap;
    if (hasLoading || hasError) {
      width += 11 + 4; // иконка + отступ
    }
    if (showTime) {
      final timeStyle = AppText.lowTextStyle.copyWith(fontSize: 10);
      width += _measureTextWidth(UtilDate.formatTime(message.time), timeStyle);
      if (isMine) width += 4;
    }
    if (isMine) {
      width += isRead ? 18 : 12; // двойная/одинарная галочка
    }
    return width;
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
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

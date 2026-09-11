// lib/presentation/features/message/message_item.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/ui/message_tail_direction.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/presentation/features/message/widgets/answer_preview.dart';
import 'package:disalive/presentation/features/message/widgets/link_preview.dart';
import 'package:disalive/presentation/features/message/widgets/media/grids/audios_grid.dart';
import 'package:disalive/presentation/features/message/widgets/media/grids/files_grid.dart';
import 'package:disalive/presentation/features/message/widgets/media/grids/images_grid.dart';
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
    this.onTapImage,
  });

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
    // Картинки идут в MediaGrid, остальные типы вложений (файлы, видео,
    // аудио) пока показываем общей заглушкой ниже.
    final List<FileMessage> imageAttachments =
        contentMessage.attachments
            ?.where((f) => f.isImageFile && f.hasValidPath)
            .toList() ??
        const [];
    final List<FileMessage> audiosAttachments =
        contentMessage.attachments
            ?.where((f) => f.isAudioFile && f.hasValidPath)
            .toList() ??
        const [];
    final List<FileMessage> otherAttachments =
        contentMessage.attachments
            ?.where(
              (f) =>
                  f.isDefaultFile &&
                  !f.isImageFile &&
                  !f.isAudioFile &&
                  f.hasValidPath,
            )
            .toList() ??
        const [];
    final hasReactions = message.reactions?.isNotEmpty ?? false;
    final hasAnswer = message.answerMessage != null;
    final showSenderInfo = !isMine && showSender && showAvatar;
    final showStatusRow = isMine || showTime || hasLoading || hasError;
    final hasText = (contentMessage.text ?? '').isNotEmpty;
    // Время/галочки "втекают" в последнюю строку текста (как в Telegram/VK)
    // только для чистых текстовых сообщений — без медиа, вложений, превью
    // ссылки, приглашения или реакций, у которых уже есть своя раскладка.
    final bool useInlineStatus =
        showStatusRow &&
        hasText &&
        !hasLinkPreview &&
        !hasInviteData &&
        imageAttachments.isEmpty &&
        audiosAttachments.isEmpty &&
        otherAttachments.isEmpty &&
        !hasReactions;
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
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

                    if (hasAnswer)
                      AnswerPreview(
                        message: message.answerMessage,
                        isMine: isMine,
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
                            child: _buildStatusRow(),
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
                    if (imageAttachments.isNotEmpty) ...[
                      if ((contentMessage.text ?? '').isNotEmpty ||
                          hasAnswer ||
                          hasForward)
                        const SizedBox(height: 4),
                      ImagesGrid(
                        images: imageAttachments,
                        onTapImage: onTapImage,
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (audiosAttachments.isNotEmpty) ...[
                      if ((contentMessage.text ?? '').isNotEmpty ||
                          hasAnswer ||
                          hasForward ||
                          imageAttachments.isNotEmpty)
                        const SizedBox(height: 4),
                      AudiosGrid(audios: audiosAttachments, isMine: isMine),
                    ],
                    if (otherAttachments.isNotEmpty) ...[
                      if ((contentMessage.text ?? '').isNotEmpty ||
                          hasAnswer ||
                          hasForward ||
                          imageAttachments.isNotEmpty ||
                          audiosAttachments.isNotEmpty)
                        const SizedBox(height: 4),
                      FilesGrid(files: otherAttachments, isMine: isMine),
                    ],
                    if (hasReactions) _stubLine('Реакции'),

                    if (showStatusRow && !useInlineStatus) ...[
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildStatusRow(),
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

  Widget _buildStatusRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Иконка ошибки или загрузки (если есть)
        if (hasLoading || hasError) ...[
          Icon(
            hasError ? CupertinoIcons.exclamationmark_circle : getLoadingIcon(),
            size: 11,
            color: hasError
                ? CupertinoColors.systemRed
                : (isMine
                      ? AppColors.onBlurple.withValues(alpha: 0.7)
                      : AppColors.greyple),
          ),
          const SizedBox(width: 4),
        ],

        // 2. Время (если пришло время его показать)
        if (showTime) ...[
          Text(
            UtilDate.formatTime(message.time),
            style: AppText.lowTextStyle.copyWith(
              color: isMine
                  ? AppColors.onBlurple.withValues(alpha: 0.7)
                  : AppColors.greyple,
              fontSize: 10,
            ),
          ),
          // 🎯 Умный отступ: нужен только если рядом будут галочки
          if (isMine) const SizedBox(width: 4),
        ],

        if (isMine) _buildReadStatus(),
      ],
    );
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

  Widget _buildReadStatus() {
    final Color color = isRead
        ? AppColors.onBlurple
        : AppColors.onBlurple.withValues(alpha: 0.7);

    if (!isRead) {
      return Icon(CupertinoIcons.checkmark_alt, size: 12, color: color);
    }

    // Раньше вторая галочка сдвигалась через Transform.translate(-6, 0) —
    // это сдвигает только отрисовку, а не layout. Row всё равно занимал
    // 12 + 12 = 24px, хотя визуально галочки выглядели как 18px. Эти
    // "лишние" 6px и были тем самым пустым местом справа от статуса,
    // о котором речь. SizedBox+Stack ниже фиксирует реальный layout-размер
    // ровно в 18px — как и предполагает _statusReserveWidth().
    return SizedBox(
      width: 18,
      height: 12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            child: Icon(CupertinoIcons.checkmark_alt, size: 12, color: color),
          ),
          Positioned(
            left: 6,
            child: Icon(CupertinoIcons.checkmark_alt, size: 12, color: color),
          ),
        ],
      ),
    );
  }
}

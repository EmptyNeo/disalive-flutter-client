// lib/presentation/features/message/message_item.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/presentation/utils/util_date.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

/// Элемент списка сообщений в чате.
///
/// Сейчас отображаются только: аватар/имя отправителя (в групповых чатах),
/// текст сообщения и время отправки. Наличие остальных частей сообщения
/// (превью ссылки, приглашение, вложения, реакции, ответ, пересылка) уже
/// проверяется, но вёрстка под них — заглушка с пометкой [в разработке],
/// сделаем отдельно.
class MessageItem extends StatelessWidget {
  const MessageItem({
    super.key,
    required this.message,
    required this.isMine,
    this.showSender = false,
  });

  final Message message;

  /// Сообщение отправлено текущим пользователем — определяет выравнивание.
  final bool isMine;

  /// Показывать ли аватар/имя отправителя (актуально для групповых чатов).
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    final hasLinkPreview = message.linkPreview != null;
    final hasInviteData = message.inviteData != null;
    final hasAttachments = message.attachments?.isNotEmpty ?? false;
    final hasReactions = message.reactions?.isNotEmpty ?? false;
    final hasAnswer = message.answerMessage != null;
    final hasForward = message.forwardMessage != null;
    final showSenderInfo = !isMine && showSender;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showSenderInfo) ...[
            BuildAvatar(url: message.user?.pathImage, wh: 26, size: 16),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMine ? AppColors.blurple : AppColors.actionGrey,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMine ? 14 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSenderInfo && message.user != null) ...[
                    Text(
                      message.user!.displayName ?? '',
                      style: AppText.lowTextStyle.copyWith(
                        color: AppColors.blurple,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],

                  if (hasForward) _stubLine('Пересланное сообщение'),
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

                  const SizedBox(height: 2),
                  // Используем Row с mainAxisSize.min, чтобы пузырь не
                  // растягивался на всю ширину из-за Align
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.time),
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
              ),
            ),
          ),
        ],
      ),
    );
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

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

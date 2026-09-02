// presentation/features/message/widgets/forward_message_preview.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

/// Компактное превью пересланного сообщения — как в Discord: маленький
/// аватар + имя автора + обрезанный текст, с тонкой акцентной полоской
/// слева. НЕ переиспользует [MessageItem] — рекурсивный рендер целого
/// сообщения внутри сообщения даёт пузырь-в-пузыре (свой фон, свой
/// padding, свои скруглённые углы и лишний таймштамп поверх основного
/// бабла), а тут нужен один плоский слой превью, а не вложенный чат-бабл.
class ForwardedMessagePreview extends StatelessWidget {
  const ForwardedMessagePreview({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final forward = message.forwardMessage;
    if (forward == null) return const SizedBox.shrink();

    final displayName = forward.user?.displayName ?? 'Пользователь';
    final label = 'Переслано от $displayName';
    final preview = _previewText(forward);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2,
            margin: const EdgeInsets.only(top: 2, bottom: 2),
            constraints: const BoxConstraints(minHeight: 26),
            decoration: BoxDecoration(
              color: AppColors.blurple.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 8),
          BuildAvatar(url: forward.user?.pathImage, wh: 18, size: 11),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.lowTextStyle.copyWith(
                    color: AppColors.linkBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (preview.isNotEmpty)
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.lowTextStyle.copyWith(
                      color: AppColors.greyple,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Если у пересланного сообщения нет текста (только вложение/ссылка/
  // приглашение), показываем короткую подпись вместо пустой строки —
  // сама верстка вложений внутри превью пока не нужна, это просто
  // индикатор содержимого.
  String _previewText(Message forward) {
    if ((forward.text ?? '').isNotEmpty) return forward.text!;
    if (forward.attachments?.isNotEmpty ?? false) return '📎 Вложение';
    if (forward.linkPreview != null) return '🔗 Ссылка';
    if (forward.inviteData != null) return 'Приглашение';
    return 'Сообщение';
  }
}
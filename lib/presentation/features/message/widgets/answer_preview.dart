// lib/presentation/features/message/widgets/answer_preview.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/presentation/utils/ui/pluralize.dart';
import 'package:flutter/cupertino.dart';

/// Превью сообщения, на которое отвечают ("Ответ на сообщение") — цветная
/// полоска слева + имя автора оригинала + текст (или "Фото"/"Вложение",
/// если текста нет, или "Пересланное сообщение", если это реплай на форвард).
///
/// [message] — это уже сам `answerMessage`, а не сообщение-обёртка.
/// [isMine] — от чьего лица бабл, в котором лежит превью (влияет на
/// цвета, чтобы всё осталось читаемым и на синем, и на сером фоне).
class AnswerPreview extends StatelessWidget {
  const AnswerPreview({
    super.key,
    required this.message,
    this.isMine = false,
    this.onTap,
  });

  final Message? message;
  final bool isMine;

  /// Опционально — например, для перехода к оригиналу сообщения по тапу.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 🎯 1. Проверяем, является ли сообщение, на которое отвечают, пересланным
    final isForwarded = message?.isForward ?? false;

    final String previewText;
    if (isForwarded) {
      previewText = 'Пересланное сообщение';
    } else {
      // 🎯 3. Стандартная логика для обычных сообщений
      final amountFiles = message?.amountFiles ?? 0;
      final text = message?.text ?? '';

      final parts = <String>[
        if (text.isNotEmpty) text,
        if (amountFiles > 0) '[${Pluralize.attachments(amountFiles)}]',
      ];

      previewText = parts.isNotEmpty ? parts.join(' ') : 'Вложение';
    }

    final accentColor = isMine ? AppColors.onBlurple : AppColors.blurple;
    final nameColor = accentColor;
    final textColor = AppColors.onBlurple.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isMine ? AppColors.onBlurple : AppColors.white).withValues(
            alpha: 0.08,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      message?.user?.displayName ?? 'Пользователь',
                      style: AppText.lowTextStyle.copyWith(
                        color: nameColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (previewText.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        previewText,
                        style: AppText.lowTextStyle.copyWith(color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

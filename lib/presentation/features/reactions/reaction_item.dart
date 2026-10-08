// lib/presentation/features/message/widgets/reactions/reaction_item.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/reaction_message.dart';
import 'package:disalive/presentation/utils/ui/emoji_text_parser.dart';
import 'package:flutter/cupertino.dart';

class ReactionItem extends StatelessWidget {
  final ReactionMessage reaction;
  final bool isMine;
  final VoidCallback? onTap;

  final double? minWidth;
  final double? minHeight;
  final double emojiSize;

  const ReactionItem({
    super.key,
    required this.reaction,
    required this.isMine,
    this.onTap,
    this.minWidth,
    this.minHeight,
    this.emojiSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = reaction.hasReaction;
    final amount = reaction.amount ?? 0;

    final Color backgroundColor = isMine
        ? (isActive
        ? AppColors.highlight.withValues(alpha: 0.25)
        : AppColors.highlight.withValues(alpha: 0.1))
        : (isActive ? AppColors.highlight : AppColors.glassPanelTop);

    final Color borderColor = isMine
        ? (isActive
        ? AppColors.divider
        : AppColors.divider.withValues(alpha: 0.3))
        : (isActive ? AppColors.blurple : AppColors.divider);

    final Color textColor = isMine
        ? (isActive ? AppColors.white : AppColors.white.withValues(alpha: 0.85))
        : (isActive ? AppColors.blurple : AppColors.white);

    // 🎯 ОПРЕДЕЛЯЕМ РЕЖИМ: если minWidth задан, значит мы хотим фиксированный/растянутый размер (как в шторке)
    final bool isFixedSize = minHeight != null && minHeight! > 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints(
          minWidth: minWidth ?? 0.0,
          minHeight: minHeight ?? 0.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Row(
          // 🎯 УМНОЕ ПОВЕДЕНИЕ:
          mainAxisSize: isFixedSize ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: isFixedSize ? MainAxisAlignment.center : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                children: EmojiTextParser.parse(
                  reaction.nameReaction ?? '',
                  emojiSize: emojiSize,
                ),
              ),
            ),
            if (amount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$amount',
                style: AppText.lowTextStyle.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
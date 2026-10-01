// lib/presentation/features/message/widgets/reactions/reaction_item.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/reaction_message.dart';
import 'package:disalive/presentation/utils/ui/emoji_text_parser.dart';
import 'package:flutter/cupertino.dart';

/// Один "чип" реакции под сообщением: кастомный эмодзи (в формате
/// `[category:id]`, который умеет рисовать [EmojiTextParser]) + счётчик.
/// Если реакцию поставил сам пользователь ([ReactionMessage.hasReaction]),
/// чип подсвечивается акцентным цветом темы.
class ReactionItem extends StatelessWidget {
  static const double _emojiSize = 16;

  final ReactionMessage reaction;
  final VoidCallback? onTap;

  const ReactionItem({super.key, required this.reaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = reaction.hasReaction;
    final amount = reaction.amount ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.highlight : AppColors.actionGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.blurple : AppColors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: EmojiTextParser.parse(
                  reaction.nameReaction ?? '',
                  emojiSize: _emojiSize,
                ),
              ),
            ),
            if (amount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$amount',
                style: AppText.lowTextStyle.copyWith(
                  color: isActive ? AppColors.blurple : AppColors.greyple,
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
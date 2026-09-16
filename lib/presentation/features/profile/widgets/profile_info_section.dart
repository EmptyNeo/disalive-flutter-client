// lib/presentation/features/profile/widgets/profile_info_section.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class ProfileInfoSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;

  const ProfileInfoSection({
    super.key,
    required this.title,
    required this.content,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.actionGrey,
        borderRadius: BorderRadius.circular(12),
        // 🎯 Скругление как в оригинале
        border: Border.all(
          // 🎯 Динамическая рамка, видимая в любой теме
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
              ],
              Text(
                title.toUpperCase(),
                style: AppText.lowTextStyle.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppText.mediumTextStyle.copyWith(
              // 🎯 Динамический цвет текста (белый в Dark, почти чёрный в Light)
              color: AppColors.white.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/badge.dart';
import 'package:disalive/domain/models/badge_user.dart';
import 'package:disalive/presentation/features/profile/items/badge_item.dart';
import 'package:flutter/cupertino.dart';

class ProfileBadgesSection extends StatelessWidget {
  final List<BadgeUserModel> badges;

  const ProfileBadgesSection({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    final visibleBadges = badges
        .where((bu) => bu.isVisible == true && bu.badge != null)
        .toList();

    if (visibleBadges.isEmpty) return const SizedBox.shrink();

    // 🎯 ИСПОЛЬЗУЕМ ТОЧНО ТАКУЮ ЖЕ ОБОЛОЧКУ, КАК В ProfileInfoSection
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12), // Тот же внутренний отступ
      decoration: BoxDecoration(
        color: AppColors.actionGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 Заголовок в точности как в ProfileInfoSection (с иконкой трофея/звезды)
          Row(
            children: [
              Icon(
                CupertinoIcons.star_fill, // Или CupertinoIcons.trophy_fill
                size: 16,
                color: AppColors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'НАГРАЖДЕН', // В верхнем регистре, как и другие заголовки
                style: AppText.lowTextStyle.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          // Тот же отступ до контента

          // 🎯 Компактная сетка бейджей внутри карточки
          Wrap(
            spacing: 4,
            runSpacing: 12,
            children: visibleBadges
                .map((bu) => BadgeItem(badge: bu.badge!))
                .toList(),
          ),
        ],
      ),
    );
  }
}

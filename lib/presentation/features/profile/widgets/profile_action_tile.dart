import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.actionGrey, // 🎯 Динамический фон
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5), // 🎯 Динамическая рамка
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppText.mediumTextStyle.copyWith(
                color: AppColors.white, // 🎯 Динамический цвет
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.greyple,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
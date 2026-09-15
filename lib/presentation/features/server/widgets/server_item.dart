import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/features/server/widgets/unread_badge.dart';
import 'package:flutter/cupertino.dart';

class ServerItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isSpecial;
  final bool isAction;
  final int unreadCount;

  const ServerItem({
    super.key,
    required this.icon,
    required this.isActive,
    required this.unreadCount,
    this.isSpecial = false,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: isActive ? 32 : 0,
          decoration: BoxDecoration(
            // 🎯 ЗАМЕНЕНО: AppColors.white динамический (белый в Dark, почти чёрный в Light)
            color: AppColors.blurple,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // clipBehavior: Clip.none — бейдж специально выходит за пределы
        // 48x48 иконки в правый нижний угол, обрезать его нельзя.
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // 🎯 ЗАМЕНЕНО: AppColors.actionGrey вместо белого с прозрачностью
                color: isActive ? AppColors.blurple : AppColors.actionGrey,
                borderRadius: BorderRadius.circular(isActive ? 16 : 24),
              ),
              child: Icon(
                icon,
                // 🎯 ЗАМЕНЕНО: AppColors.white для иконки (динамический контраст)
                color: isAction ? AppColors.onBlurple : AppColors.white,
                size: 24,
              ),
            ),
            if (hasUnread)
              Positioned(
                right: -4,
                bottom: -4,
                child: UnreadBadge(count: unreadCount),
              ),
          ],
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

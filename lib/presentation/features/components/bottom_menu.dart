import 'dart:ui';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/components/widgets/nav_unread_badge.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

class BottomMenu extends StatelessWidget {
  final UserModel user;
  final ValueChanged<int> onTapTapped;
  final int currentIndex;
  final int personalUnreadCount;

  const BottomMenu({
    super.key,
    required this.user,
    required this.onTapTapped,
    required this.currentIndex,
    required this.personalUnreadCount,
  });

  void _onTabTapped(int index) {
    if (currentIndex == index) return;
    onTapTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // Изменил на 32, чтобы совпадало с высотой 64 (идеальная пилюля)
      // и с радиусом внутреннего Container. Если дизайн требует 24, верните 24.
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.darkGrey.withOpacity(0.65),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.white.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / 3;
              double containerWidth = currentIndex == 0 ? 54 : 74;
              return ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    // Анимированный плавающий фон активного элемента
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: currentIndex * itemWidth,
                      top: 6,
                      bottom: 6,
                      child: Container(
                        width: itemWidth,
                        alignment: Alignment.center,
                        child: Container(
                          width: containerWidth,
                          decoration: BoxDecoration(
                            color: AppColors.darkGrey,
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                      ),
                    ),

                    // Сами элементы меню поверх фона
                    Row(
                      children: [
                        _buildNavItem(
                          width: itemWidth,
                          index: 0,
                          icon: currentIndex == 0
                              ? CupertinoIcons.chat_bubble_2_fill
                              : CupertinoIcons.chat_bubble_2,
                          label: 'Чаты',
                          unreadCount: personalUnreadCount,
                        ),
                        _buildNavItem(
                          width: itemWidth,
                          index: 1,
                          icon: CupertinoIcons.settings_solid,
                          label: 'Настройки',
                        ),
                        _buildProfileNavItem(
                          width: itemWidth,
                          index: 2,
                          user: user,
                          label: 'Профиль',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required double width,
    required int index,
    required IconData icon,
    required String label,
    int unreadCount = 0,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.blurple : AppColors.iconGrey;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTapped(index),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // Центрируем по вертикали
          children: [
            // Positioned работает только внутри Stack — оборачиваем сюда
            // именно иконку (не всю колонку), чтобы бейдж сидел строго
            // у её угла, а не у угла всего таба.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -2,
                    child: NavUnreadBadge(count: unreadCount),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem({
    required double width,
    required int index,
    required UserModel user,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.blurple : AppColors.iconGrey;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTapped(index),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              child: BuildAvatar(
                url: user.urlAvatar,
                wh: 24,
                size: 16,
                status: user.status,
                statusSize: 4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

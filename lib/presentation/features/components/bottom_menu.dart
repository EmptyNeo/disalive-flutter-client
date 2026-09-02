import 'dart:ui';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

class BottomMenu extends StatelessWidget {
  final UserModel user;
  final ValueChanged<int> onTapTapped;
  final int currentIndex;

  const BottomMenu({
    super.key,
    required this.user,
    required this.onTapTapped,
    required this.currentIndex,
  });

  void _onTabTapped(int index) {
    if (currentIndex == index) return;
    onTapTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64, // Фиксируем общую высоту для корректной работы Stack
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
              // Высчитываем ширину одной секции (всего их 3)
              final itemWidth = constraints.maxWidth / 3;
              double containerWidth = currentIndex == 0 ? 54 : 74;

              return Stack(
                children: [
                  // Анимированный плавающий фон активного элемента
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    // Плавная iOS-подобная кривая
                    left: currentIndex * itemWidth,
                    top: 6,
                    bottom: 6,
                    child: Container(
                      width: itemWidth,
                      alignment: Alignment.center,
                      child: Container(
                        width: containerWidth, // Ширина самой плашки
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
            Icon(icon, color: color, size: 24),
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

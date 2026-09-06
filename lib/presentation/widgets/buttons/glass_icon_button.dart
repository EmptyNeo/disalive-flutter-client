import 'dart:ui';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.size = 36.0,
    this.blur, // Оставил, но см. примечание ниже
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final double size;
  final double? blur;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero, // Убираем все внутренние отступы кнопки
      minSize: size,            // Используем minSize (правильное свойство для CupertinoButton)
      onPressed: onTap,
      child: Center(            // 1. Гарантируем центрирование всего блока
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.blurple : AppColors.lightGrey,
            border: Border.all(
              color: filled ? AppColors.blurple : AppColors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Center(        // 2. Двойное центрирование для иконки
            child: Icon(
              icon,
              size: size * 0.5, // Чуть увеличил с 0.48 до 0.5 для лучшей визуальной пропорции
              color: filled ? AppColors.onBlurple : AppColors.iconGrey,
            ),
          ),
        ),
      ),
    );
  }
}
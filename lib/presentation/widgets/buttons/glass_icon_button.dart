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
    this.borderRadius,
    this.hasBorderRadius = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final double size;
  final double? blur;
  final BorderRadiusGeometry? borderRadius;

  final bool hasBorderRadius;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      // Используем minSize (правильное свойство для CupertinoButton)
      onPressed: onTap,
      minimumSize: Size(size, size),
      child: Center(
        // 1. Гарантируем центрирование всего блока
        child: Container(
          alignment: Alignment.center,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: hasBorderRadius ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: hasBorderRadius ? borderRadius : null,
            color: filled ? AppColors.blurple : AppColors.lightGrey,
            border: Border.all(
              color: filled
                  ? AppColors.blurple
                  : AppColors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Center(
            // 2. Двойное центрирование для иконки
            child: Icon(
              icon,
              size: size * 0.5,
              color: filled ? AppColors.onBlurple : AppColors.iconGrey,
            ),
          ),
        ),
      ),
    );
  }
}

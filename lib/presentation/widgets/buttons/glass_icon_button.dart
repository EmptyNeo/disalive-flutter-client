import 'dart:ui';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.size = 36,
    this.blur = 10, // Добавляем параметр блюра
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final double size;
  final double? blur; // null — без блюра

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled
            ? AppColors.blurple
            : AppColors.actionGrey.withOpacity(0.35), // Немного прозрачнее
        border: Border.all(
          color: filled
              ? AppColors.blurple
              : AppColors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.48,
        color: filled ? AppColors.onBlurple : AppColors.iconGrey,
      ),
    );

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      minimumSize: Size(size, size),
      child: blur != null
          ? ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur!, sigmaY: blur!),
          child: button,
        ),
      )
          : button,
    );
  }
}
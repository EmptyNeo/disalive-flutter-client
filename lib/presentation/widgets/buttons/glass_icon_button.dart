import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.size = 36,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      minimumSize: Size(size, size),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? AppColors.blurple
              : AppColors.actionGrey.withOpacity(0.65),
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
      ),
    );
  }
}

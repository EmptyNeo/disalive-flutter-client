import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.padding,
    required this.onTap,
    this.accent = false,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: accent
              ? AppColors.blurple.withValues(alpha: 0.6)
              : AppColors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: accent
                ? AppColors.blurple.withValues(alpha: 0.35)
                : AppColors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
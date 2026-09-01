import 'package:disalive/app/theme/app_theme.dart';

import 'package:flutter/cupertino.dart';

class GlassButton extends StatefulWidget {
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
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;

    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.6 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: widget.accent
                ? AppColors.blurple.withValues(alpha: 0.16)
                : AppColors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: widget.accent
                  ? AppColors.blurple.withValues(alpha: 0.35)
                  : AppColors.white.withValues(alpha: 0.12),

              width: 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

/// Applies the spoiler blur and reveals the media after the first tap.
/// Further taps are forwarded to [onTapRevealed].
class SpoilerMediaPreview extends StatefulWidget {
  const SpoilerMediaPreview({
    super.key,
    required this.isSpoiler,
    required this.childBuilder,
    this.onTapRevealed,
    this.borderRadius = BorderRadius.zero,
  });

  final bool isSpoiler;
  final Widget Function(BuildContext context, bool isRevealed) childBuilder;
  final VoidCallback? onTapRevealed;
  final BorderRadius borderRadius;

  @override
  State<SpoilerMediaPreview> createState() => _SpoilerMediaPreviewState();
}

class _SpoilerMediaPreviewState extends State<SpoilerMediaPreview> {
  late bool _isRevealed = !widget.isSpoiler;

  @override
  void didUpdateWidget(covariant SpoilerMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSpoiler != widget.isSpoiler) {
      _isRevealed = !widget.isSpoiler;
    }
  }

  void _handleTap() {
    if (widget.isSpoiler && !_isRevealed) {
      setState(() => _isRevealed = true);
      return;
    }
    widget.onTapRevealed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isHidden = widget.isSpoiler && !_isRevealed;
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Stack(
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: isHidden ? 14 : 0,
                sigmaY: isHidden ? 14 : 0,
              ),
              child: widget.childBuilder(context, _isRevealed),
            ),
            if (isHidden)
              Positioned.fill(
                child: ColoredBox(
                  color: CupertinoColors.black.withValues(alpha: 0.22),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.eye_slash,
                      color: CupertinoColors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:disalive/domain/models/emojis/emoji_definition.dart';
import 'package:disalive/domain/models/emojis/emoji_sheet_data.dart';
import 'package:flutter/material.dart';

class EmojiWidget extends StatefulWidget {
  final EmojiDefinition emoji;
  final EmojiSheetData sheetData;
  final double size;
  final double frameInset;
  final Function(EmojiDefinition emoji)? onTap;
  final bool animate; // 🎯 НОВЫЙ ПАРАМЕТР

  const EmojiWidget({
    super.key,
    required this.emoji,
    required this.sheetData,
    this.size = 24,
    this.frameInset = 0,
    this.onTap,
    this.animate = true, // По умолчанию включена (для сообщений)
  });

  @override
  State<EmojiWidget> createState() => _EmojiWidgetState();
}

class _EmojiWidgetState extends State<EmojiWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller; // 🎯 Nullable, так как может не создаваться
  int _currentFrameIndex = 0;

  @override
  void initState() {
    super.initState();
    // 🎯 Создаём контроллер ТОЛЬКО если animate == true
    if (widget.animate &&
        widget.emoji.isAnimated &&
        widget.sheetData.fps != null) {
      final duration = Duration(
        milliseconds:
            (1000 / widget.sheetData.fps! * widget.emoji.frames.length).round(),
      );
      _controller = AnimationController(vsync: this, duration: duration)
        ..addListener(() {
          final frame = (_controller!.value * widget.emoji.frames.length)
              .floor();
          if (frame != _currentFrameIndex) {
            setState(() {
              _currentFrameIndex = frame % widget.emoji.frames.length;
            });
          }
        });
      _controller!.repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.emoji.frames[_currentFrameIndex];

    final frameWidth = widget.sheetData.frameWidth - widget.frameInset * 2;
    final frameHeight = widget.sheetData.frameHeight - widget.frameInset * 2;
    final scaleX = widget.size / frameWidth;
    final scaleY = widget.size / frameHeight;

    final scaledWidth = widget.sheetData.sheetWidth * scaleX;
    final scaledHeight = widget.sheetData.sheetHeight * scaleY;

    return GestureDetector(
      onTap: widget.onTap != null ? () => widget.onTap!(widget.emoji) : null,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: -(frame.x + widget.frameInset) * scaleX,
                top: -(frame.y + widget.frameInset) * scaleY,
                child: Image.asset(
                  'assets/emojis/${widget.sheetData.assetPath}',
                  width: scaledWidth,
                  height: scaledHeight,
                  fit: widget.frameInset > 0 ? BoxFit.fill : null,
                  gaplessPlayback: widget.animate && widget.emoji.isAnimated,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

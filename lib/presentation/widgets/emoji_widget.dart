import 'dart:ui' as ui;

import 'package:disalive/domain/models/emojis/emoji_data.dart';
import 'package:disalive/domain/models/emojis/emoji_definition.dart';
import 'package:disalive/domain/models/emojis/emoji_sheet_data.dart';
import 'package:disalive/data/network/domain.dart';
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
    with TickerProviderStateMixin {
  AnimationController? _controller; // 🎯 Nullable, так как может не создаваться
  int _currentFrameIndex = 0;
  ui.Image? _spriteImage;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  String get _spritePath =>
      widget.emoji.spritePath ?? widget.sheetData.assetPath;

  @override
  void initState() {
    super.initState();
    _configureAnimation();
  }

  @override
  void didUpdateWidget(covariant EmojiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emoji.spritePath != widget.emoji.spritePath ||
        oldWidget.sheetData.assetPath != widget.sheetData.assetPath) {
      _resolveSpriteImage();
    }
    if (oldWidget.emoji != widget.emoji ||
        oldWidget.sheetData != widget.sheetData ||
        oldWidget.animate != widget.animate) {
      _configureAnimation();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveSpriteImage();
  }

  void _resolveSpriteImage() {
    final transformedPath = Domain.transformUrl(_spritePath);
    final uri = Uri.tryParse(transformedPath);
    final isNetwork =
        widget.sheetData.isNetworkAsset ||
        (uri?.hasScheme ?? false) ||
        transformedPath.startsWith('/');
    final ImageProvider provider;
    if (isNetwork) {
      final imageUrl = uri?.hasScheme == true
          ? transformedPath
          : Uri.parse(Domain.imageDomain).resolve(transformedPath).toString();
      provider = NetworkImage(imageUrl);
    } else {
      provider = AssetImage(
        transformedPath.startsWith('assets/')
            ? transformedPath
            : 'assets/emojis/$transformedPath',
      );
    }

    final stream = provider.resolve(createLocalImageConfiguration(context));
    if (_imageStream?.key == stream.key) return;
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageStream = stream;
    _spriteImage = null;
    _imageListener = ImageStreamListener((imageInfo, _) {
      if (!mounted) return;
      setState(() => _spriteImage = imageInfo.image);
    });
    stream.addListener(_imageListener!);
  }

  void _configureAnimation() {
    _controller?.dispose();
    _controller = null;
    _currentFrameIndex = 0;
    final frameCount = widget.emoji.frames.length;
    final fps = widget.emoji.fps ?? widget.sheetData.fps;
    if (!widget.animate ||
        !widget.emoji.isAnimated ||
        fps == null ||
        fps <= 0) {
      return;
    }

    final duration = Duration(
      milliseconds: (1000 / fps * frameCount).round().clamp(1, 1 << 31),
    );
    final controller = AnimationController(vsync: this, duration: duration);
    _controller = controller
      ..addListener(() {
        if (!mounted || frameCount == 0) return;
        final frame = (controller.value * frameCount).floor() % frameCount;
        final nextFrame = widget.emoji.loop
            ? frame
            : frame.clamp(0, frameCount - 1).toInt();
        if (nextFrame != _currentFrameIndex) {
          setState(() => _currentFrameIndex = nextFrame);
        }
      });
    if (widget.emoji.loop) {
      controller.repeat();
    } else {
      controller.forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sheetData.isNetworkAsset) {
      final frame = widget.emoji.frames.isEmpty
          ? EmojiFrame(x: 0, y: 0)
          : widget.emoji.frames[_currentFrameIndex];
      final frameWidth = widget.emoji.frameWidth ?? widget.sheetData.frameWidth;
      final frameHeight =
          widget.emoji.frameHeight ?? widget.sheetData.frameHeight;
      final inset = widget.frameInset;
      return GestureDetector(
        onTap: widget.onTap != null ? () => widget.onTap!(widget.emoji) : null,
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _EmojiFramePainter(
            image: _spriteImage,
            source: Rect.fromLTWH(
              frame.x + inset,
              frame.y + inset,
              (frameWidth - inset * 2).clamp(1, frameWidth).toDouble(),
              (frameHeight - inset * 2).clamp(1, frameHeight).toDouble(),
            ),
            size: widget.size,
          ),
        ),
      );
    }
    if (widget.emoji.frames.isEmpty) {
      return SizedBox.square(dimension: widget.size);
    }
    final frame = widget.emoji.frames[_currentFrameIndex];
    final spritePath = _spritePath;

    final frameWidth =
        (widget.emoji.frameWidth ?? widget.sheetData.frameWidth) -
        widget.frameInset * 2;
    final frameHeight =
        (widget.emoji.frameHeight ?? widget.sheetData.frameHeight) -
        widget.frameInset * 2;
    final scaleX = widget.size / frameWidth;
    final scaleY = widget.size / frameHeight;

    final scaledWidth =
        (widget.emoji.sheetWidth ?? widget.sheetData.sheetWidth) * scaleX;
    final scaledHeight =
        (widget.emoji.sheetHeight ?? widget.sheetData.sheetHeight) * scaleY;

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
                child: _buildSpriteImage(
                  spritePath,
                  width: scaledWidth,
                  height: scaledHeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpriteImage(
    String spritePath, {
    required double width,
    required double height,
  }) {
    final transformedPath = Domain.transformUrl(spritePath);
    final uri = Uri.tryParse(transformedPath);
    final isNetwork =
        widget.sheetData.isNetworkAsset ||
        (uri?.hasScheme ?? false) ||
        transformedPath.startsWith('/');
    final image = isNetwork
        ? Image.network(
            uri?.hasScheme == true
                ? transformedPath
                : Uri.parse(
                    Domain.imageDomain,
                  ).resolve(transformedPath).toString(),
            width: width,
            height: height,
            fit: widget.frameInset > 0 ? BoxFit.fill : null,
            gaplessPlayback: widget.animate && widget.emoji.isAnimated,
            filterQuality: FilterQuality.high,
          )
        : Image.asset(
            transformedPath.startsWith('assets/')
                ? transformedPath
                : 'assets/emojis/$transformedPath',
            width: width,
            height: height,
            fit: widget.frameInset > 0 ? BoxFit.fill : null,
            gaplessPlayback: widget.animate && widget.emoji.isAnimated,
            filterQuality: FilterQuality.high,
          );
    return image;
  }
}

class _EmojiFramePainter extends CustomPainter {
  const _EmojiFramePainter({
    required this.image,
    required this.source,
    required this.size,
  });

  final ui.Image? image;
  final Rect source;
  final double size;

  @override
  void paint(Canvas canvas, Size _) {
    final sprite = image;
    if (sprite == null ||
        source.width <= 0 ||
        source.height <= 0 ||
        source.right > sprite.width ||
        source.bottom > sprite.height) {
      return;
    }
    canvas.drawImageRect(
      sprite,
      source,
      Rect.fromLTWH(0, 0, size, size),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _EmojiFramePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.source != source ||
      oldDelegate.size != size;
}

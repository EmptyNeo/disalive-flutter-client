import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';

class VideoPlayItem extends StatefulWidget {
  final String source;
  final bool isNetwork;
  final bool autoPlay;

  /// true — страница сейчас на экране. На неактивной странице видео
  /// не запускается и ставится на паузу.
  final bool isActive;

  /// Превью, которое показывается, пока видео инициализируется.
  final String? placeholderUrl;

  const VideoPlayItem({
    super.key,
    required this.source,
    required this.isNetwork,
    this.autoPlay = true,
    this.isActive = true,
    this.placeholderUrl,
  });

  @override
  State<VideoPlayItem> createState() => _VideoPlayItemState();
}

class _VideoPlayItemState extends State<VideoPlayItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final controller = widget.isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(widget.source))
        : VideoPlayerController.file(File(widget.source));
    _controller = controller;

    try {
      await controller.initialize();
      // Если пока грузилось, виджет уже удалили — dispose() сам закрыл контроллер
      if (!mounted) return;

      controller.addListener(_videoListener);
      setState(() => _isInitialized = true);

      if (widget.autoPlay && widget.isActive) {
        await controller.play();
      }
    } catch (e) {
      debugPrint('Ошибка инициализации видео: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _videoListener() {
    if (!mounted) return;
    final playing = _controller!.value.isPlaying;
    if (playing != _isPlaying) {
      setState(() => _isPlaying = playing);
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller == null || !_isInitialized) return;

    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        if (widget.autoPlay) controller.play();
      } else {
        controller.pause();
      }
    }
  }

  Future<void> _togglePlayPause() async {
    final controller = _controller;
    if (controller == null || !_isInitialized) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      final v = controller.value;
      // Видео доиграло до конца — начинаем сначала
      if (v.duration > Duration.zero && v.position >= v.duration) {
        await controller.seekTo(Duration.zero);
      }
      await controller.play();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // тап по всей области, не только по видео
      onTap: _togglePlayPause,
      child: Center(
        child: _hasError
            ? _buildError()
            : _isInitialized
            ? _buildPlayer()
            : _buildLoading(),
      ),
    );
  }

  Widget _buildPlayer() {
    final ratio = _controller!.value.aspectRatio;

    return AspectRatio(
      aspectRatio: ratio > 0 ? ratio : 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_controller!),
          if (!_isPlaying)
            Container(
              color: CupertinoColors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CupertinoColors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.play_fill,
                    color: CupertinoColors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.placeholderUrl != null)
          CachedNetworkImage(
            imageUrl: widget.placeholderUrl!,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        const Center(
          child: CupertinoActivityIndicator(
            radius: 16,
            color: CupertinoColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      color: AppColors.actionGrey,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: AppColors.errorRed,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Ошибка воспроизведения',
            style: TextStyle(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

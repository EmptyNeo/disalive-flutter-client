import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

class StickerItem extends StatefulWidget {
  const StickerItem({
    super.key,
    required this.sticker,
    this.maxSize = 140,
    this.onTap,
  });

  final FileMessage sticker;
  final double maxSize;
  final VoidCallback? onTap;

  @override
  State<StickerItem> createState() => _StickerItemState();
}

class _StickerItemState extends State<StickerItem> {
  int _retryCount = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    final url = widget.sticker.urlPath;
    if (_isVideoFormat(url)) {
      _initializeVideo(url);
    }
  }

  void _initializeVideo(String url) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..setLooping(true) // Стикеры всегда зациклены
      ..setVolume(0.0)   // Стикеры всегда без звука
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController?.play();
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _hasVideoError = true;
          });
        }
      });
  }

  void _retryLoad() {
    setState(() {
      _retryCount++;
      _hasVideoError = false;
      _isVideoInitialized = false;
    });
    final url = widget.sticker.urlPath;
    _videoController?.dispose();
    _initializeVideo(url);
    }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // 🎯 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: отбрасываем параметры URL (?token=...) перед проверкой
  bool _isVideoFormat(String url) {
    final path = url.toLowerCase().split('?').first;
    return path.endsWith('.webm') || path.endsWith('.mp4') || path.endsWith('.mov');
  }

  bool _isLottieFormat(String url) {
    final path = url.toLowerCase().split('?').first;
    return path.endsWith('.json') || path.endsWith('.tgs');
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.sticker.urlPath;

    if (url == null || url.trim().isEmpty) {
      return _buildErrorWidget();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxSize,
          maxHeight: widget.maxSize,
        ),
        child: _isVideoFormat(url)
            ? _buildVideoSticker()
            : _isLottieFormat(url)
            ? _buildLottieSticker(url)
            : _buildImageSticker(url),
      ),
    );
  }

  Widget _buildVideoSticker() {
    if (_hasVideoError || _videoController == null) {
      return _buildErrorWidget();
    }

    if (!_isVideoInitialized) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }

  Widget _buildLottieSticker(String url) {
    return Lottie.network(
      url,
      fit: BoxFit.contain,
      animate: true,
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      renderCache: RenderCache.drawingCommands,
    );
  }

  Widget _buildImageSticker(String url) {
    return CachedNetworkImage(
      key: ValueKey('${url}_$_retryCount'),
      cacheKey: '${url}_$_retryCount',
      imageUrl: url,
      fit: BoxFit.contain,

      // Защита от JNI крашей на Android
      memCacheWidth: widget.maxSize.toInt(),
      memCacheHeight: widget.maxSize.toInt(),

      placeholder: (context, url) => const Center(
        child: CupertinoActivityIndicator(),
      ),
      errorWidget: (context, url, error) => _buildErrorWidget(),
    );
  }

  Widget _buildErrorWidget() {
    return GestureDetector(
      onTap: _retryLoad,
      child: Container(
        width: widget.maxSize / 2,
        height: widget.maxSize / 2,
        decoration: BoxDecoration(
          color: AppColors.lightGrey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          CupertinoIcons.refresh_bold,
          color: AppColors.greyple,
          size: widget.maxSize / 4,
        ),
      ),
    );
  }
}
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/domain/models/sticker_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart'; // 🎯 НОВЫЙ ИМПОРТ

/// Ограничивает, сколько video-стикеров одновременно держат живой
/// VideoPlayerController. Без этого при скролле/открытии панели все
/// видимые видео-стикеры разом поднимают тяжёлые аппаратные декодеры
/// (по одному ExoPlayer/MediaCodec на каждый) — именно это и даёт лавину
/// логов инициализации и реальную нагрузку на CPU/GPU.
///
/// Кто не поместился в лимит — встаёт в очередь и получает слот, как
/// только кто-то из активных выходит из кадра и освобождает его.
class _VideoStickerGate {
  _VideoStickerGate._();

  static final _VideoStickerGate instance = _VideoStickerGate._();

  static const int maxConcurrent = 3;

  int _active = 0;
  final List<_StickerItemState> _waiting = [];

  bool tryAcquire(_StickerItemState owner) {
    if (_active < maxConcurrent) {
      _active++;
      return true;
    }
    if (!_waiting.contains(owner)) {
      _waiting.add(owner);
    }
    return false;
  }

  void release(_StickerItemState owner) {
    if (_active > 0) {
      _active--;
    }
    _promoteNext();
  }

  void cancelWaiting(_StickerItemState owner) {
    _waiting.remove(owner);
  }

  void _promoteNext() {
    while (_waiting.isNotEmpty && _active < maxConcurrent) {
      final next = _waiting.removeAt(0);
      if (!next.mounted || !next.isInViewForGate) continue;
      _active++;
      next.grantVideoSlot();
    }
  }
}

class StickerItem extends StatefulWidget {
  const StickerItem({
    super.key,
    this.file,
    this.sticker,
    this.maxSize = 140,
    this.onTap,
  });

  final FileMessage? file;
  final StickerContent? sticker;
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
  bool _isDisposed = false;

  // 🎯 ОТСЛЕЖИВАЕМ, ВИДЕН ЛИ СТИКЕР НА ЭКРАНЕ
  bool _isInView = false;

  // Debounce — не поднимаем видео на каждое мимолётное появление в кадре
  // при быстром скролле, ждём, что стикер реально задержался.
  Timer? _visibilityDebounce;

  // Держим ли мы сейчас слот в _VideoStickerGate.
  bool _holdsVideoSlot = false;

  // Публичный геттер для гейта — ему нужно проверить видимость перед тем,
  // как выдать слот из очереди ожидания.
  bool get isInViewForGate => _isInView;

  @override
  void initState() {
    super.initState();
    // Не инициализируем видео здесь! Это сделает VisibilityDetector.
  }

  String? getUrl() {
    final file = widget.file;
    final sticker = widget.sticker;
    return file?.urlPath ?? sticker?.urlPath;
  }

  void _initializeVideo(String url) {
    if (_isDisposed) return;

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..setLooping(true)
      ..setVolume(0.0)
      ..initialize()
          .then((_) {
            if (!_isDisposed && mounted && _isInView) {
              setState(() {
                _isVideoInitialized = true;
              });
              _videoController?.play();
            }
          })
          .catchError((error) {
            if (!_isDisposed && mounted) {
              setState(() {
                _hasVideoError = true;
              });
            }
          });
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
  }

  void _retryLoad() {
    if (_isDisposed) return;

    setState(() {
      _retryCount++;
      _hasVideoError = false;
      _isVideoInitialized = false;
    });

    final url = getUrl();
    if (url != null && _isVideoFormat(url) && _isInView) {
      _disposeVideo();
      // Слот на этот стикер уже удерживается с первой попытки — просто
      // переинициализируем в его рамках, заново вставать в очередь не надо.
      if (_holdsVideoSlot) {
        _initializeVideo(url);
      } else {
        _requestVideoInit(url);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _visibilityDebounce?.cancel();
    _releaseVideoSlot();
    _disposeVideo(); // Гарантированное освобождение ресурсов
    super.dispose();
  }

  bool _isVideoFormat(String url) {
    final path = url.toLowerCase().split('?').first;
    return path.endsWith('.webm') ||
        path.endsWith('.mp4') ||
        path.endsWith('.mov');
  }

  // 🎯 МАГИЯ ОПТИМИЗАЦИИ: Реагируем на изменение видимости
  void _onVisibilityChanged(VisibilityInfo info) {
    // Считаем стикер "видимым", если он показан более чем на 50%
    final isVisible = info.visibleFraction > 0.5;

    if (isVisible == _isInView) return; // Состояние не изменилось
    _isInView = isVisible;

    final url = getUrl();
    if (url == null || !_isVideoFormat(url)) return;

    _visibilityDebounce?.cancel();

    if (_isInView) {
      // Появился на экране — ждём немного, вдруг это просто мелькнул при
      // быстром скролле, а не реально задержался в кадре.
      _visibilityDebounce = Timer(const Duration(milliseconds: 200), () {
        if (!_isDisposed && mounted && _isInView) {
          _requestVideoInit(url);
        }
      });
    } else {
      // Ушёл с экрана: НЕМЕДЛЕННО убиваем декодер и отдаём слот дальше.
      _releaseVideoSlot();
      _disposeVideo();
    }
  }

  void _requestVideoInit(String url) {
    if (_VideoStickerGate.instance.tryAcquire(this)) {
      _holdsVideoSlot = true;
      _initializeVideo(url);
    }
    // Иначе — встали в очередь, gate сам вызовет grantVideoSlot(), когда
    // освободится место.
  }

  /// Вызывается _VideoStickerGate, когда для нас освободился слот.
  void grantVideoSlot() {
    if (_isDisposed || !mounted || !_isInView) {
      _VideoStickerGate.instance.release(this);
      return;
    }
    _holdsVideoSlot = true;
    final url = getUrl();
    if (url != null) _initializeVideo(url);
  }

  void _releaseVideoSlot() {
    if (_holdsVideoSlot) {
      _holdsVideoSlot = false;
      _VideoStickerGate.instance.release(this);
    } else {
      _VideoStickerGate.instance.cancelWaiting(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = getUrl();

    if (url == null || url.trim().isEmpty) {
      return _buildErrorWidget();
    }

    final double minPlaceholderSize = (widget.maxSize * 0.6).clamp(
      10.0,
      widget.maxSize,
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minPlaceholderSize,
          minHeight: minPlaceholderSize,
          maxWidth: widget.maxSize,
          maxHeight: widget.maxSize,
        ),
        // 🎯 ОБЕРТЫВАЕМ ВЕСЬ ВИДЖЕТ В DETECTOR
        child: VisibilityDetector(
          key: Key(url), // Уникальный ключ для отслеживания
          onVisibilityChanged: _onVisibilityChanged,
          child: _isVideoFormat(url)
              ? _buildVideoSticker(minPlaceholderSize)
              : _buildImageSticker(url, minPlaceholderSize), // Lottie удален
        ),
      ),
    );
  }

  Widget _buildVideoSticker(double placeholderSize) {
    if (_hasVideoError || _videoController == null) {
      return _buildErrorWidget();
    }

    if (!_isVideoInitialized) {
      return SizedBox(
        width: placeholderSize,
        height: placeholderSize,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }

  Widget _buildImageSticker(String url, double placeholderSize) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final targetCacheSize = (widget.maxSize * devicePixelRatio).round().clamp(
      1,
      480,
    );

    return CachedNetworkImage(
      key: ValueKey('${url}_$_retryCount'),
      imageUrl: url,
      fit: BoxFit.contain,
      memCacheWidth: targetCacheSize,
      // 🎯 FilterQuality.low экономит ресурсы GPU при масштабировании картинок
      filterQuality: FilterQuality.low,
      placeholder: (context, url) => SizedBox(
        width: placeholderSize,
        height: placeholderSize,
        child: const Center(child: CupertinoActivityIndicator()),
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

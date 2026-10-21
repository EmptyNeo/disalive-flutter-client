import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/widgets/app_selection_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';

class VideoPlayItem extends StatefulWidget {
  const VideoPlayItem({
    super.key,
    required this.source,
    required this.isNetwork,
    this.autoPlay = true,
    this.isActive = true,
    this.placeholderUrl,
  });

  final String source;
  final bool isNetwork;
  final bool autoPlay;
  final bool isActive;
  final String? placeholderUrl;

  @override
  State<VideoPlayItem> createState() => _VideoPlayItemState();
}

class _VideoPlayItemState extends State<VideoPlayItem> {
  final GlobalKey _videoKey = GlobalKey();
  VideoPlayerController? _controller;
  Timer? _hideTimer;
  bool _hasError = false;
  bool _showControls = true;
  bool _isMuted = false;
  double? _scrubSeconds;
  double _speed = 1;
  double? _doubleTapX;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final previous = _controller;
    if (previous != null) {
      previous.removeListener(_videoListener);
      await previous.dispose();
    }
    final controller = widget.isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(widget.source))
        : VideoPlayerController.file(File(widget.source));
    _controller = controller;
    _hasError = false;
    try {
      await controller.initialize();
      if (!mounted || !identical(_controller, controller)) {
        await controller.dispose();
        return;
      }
      controller.addListener(_videoListener);
      await controller.setVolume(_isMuted ? 0 : 1);
      await controller.setPlaybackSpeed(_speed);
      setState(() {});
      if (widget.autoPlay && widget.isActive) {
        await controller.play();
        _scheduleHide();
      }
    } catch (_) {
      if (mounted && identical(_controller, controller)) {
        setState(() => _hasError = true);
      }
    }
  }

  void _videoListener() {
    if (!mounted) return;
    setState(() => _hasError = _controller?.value.hasError ?? false);
    if (_controller?.value.isPlaying != true) _hideTimer?.cancel();
  }

  @override
  void didUpdateWidget(covariant VideoPlayItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.isNetwork != widget.isNetwork) {
      _hideTimer?.cancel();
      _showControls = true;
      _initializeVideo();
      return;
    }
    if (oldWidget.isActive != widget.isActive) {
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) return;
      if (widget.isActive && widget.autoPlay) {
        controller.play();
        _scheduleHide();
      } else {
        controller.pause();
        _hideTimer?.cancel();
        setState(() => _showControls = true);
      }
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (_controller?.value.isPlaying != true) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller?.value.isPlaying == true) {
        setState(() => _showControls = false);
      }
    });
  }

  Future<void> _togglePlayPause() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
      _hideTimer?.cancel();
      if (mounted) setState(() => _showControls = true);
    } else {
      if (controller.value.position >= controller.value.duration) {
        await controller.seekTo(Duration.zero);
      }
      await controller.play();
      if (mounted) setState(() => _showControls = true);
      _scheduleHide();
    }
  }

  void _onTapVideo() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  Future<void> _seekBy(double seconds) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final max = controller.value.duration.inMilliseconds;
    final target = (controller.value.position.inMilliseconds + seconds * 1000)
        .round()
        .clamp(0, max);
    await controller.seekTo(Duration(milliseconds: target));
    if (mounted) setState(() => _showControls = true);
    _scheduleHide();
  }

  String _time(Duration duration, {bool roundUp = false}) {
    final seconds = roundUp
        ? (duration.inMilliseconds + 999) ~/ 1000
        : duration.inSeconds;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    if (hours > 0) {
      return '$hours:${(minutes % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    }
    return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _chooseSpeed() async {
    _hideTimer?.cancel();
    final selected = await AppSelectionSheet.show<double>(
      context,
      title: 'Скорость воспроизведения',
      options: const [
        AppSelectionOption(value: 0.5, label: '0.5×'),
        AppSelectionOption(value: 1.0, label: '1×'),
        AppSelectionOption(value: 1.5, label: '1.5×'),
        AppSelectionOption(value: 2.0, label: '2×'),
      ],
      selectedValue: _speed,
    );
    if (!mounted) return;
    if (selected == null) {
      _scheduleHide();
      return;
    }
    await _controller?.setPlaybackSpeed(selected);
    setState(() => _speed = selected);
    _scheduleHide();
  }

  void _updateScrub(double dx, double width, double durationSeconds) {
    if (durationSeconds <= 0) return;
    _hideTimer?.cancel();
    final usableWidth = width - _VideoTimelinePainter.thumbRadius * 2;
    if (usableWidth <= 0) return;
    final fraction = ((dx - _VideoTimelinePainter.thumbRadius) / usableWidth)
        .clamp(0.0, 1.0);
    setState(() => _scrubSeconds = fraction * durationSeconds);
  }

  Future<void> _commitScrub() async {
    final seconds = _scrubSeconds;
    final controller = _controller;
    if (seconds == null || controller == null) return;
    setState(() => _scrubSeconds = null);
    await controller.seekTo(Duration(milliseconds: (seconds * 1000).round()));
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = !_hasError && controller?.value.isInitialized == true;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: _hasError
              ? _buildError()
              : isReady
              ? _buildPlayer(controller!)
              : _buildLoading(),
        ),
        if (isReady &&
            widget.isActive &&
            (_showControls || !controller!.value.isPlaying))
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom,
            child: _buildControls(
              controller!,
              controller.value.position.inMilliseconds / 1000,
              controller.value.duration.inMilliseconds / 1000,
            ),
          ),
      ],
    );
  }

  Widget _buildPlayer(VideoPlayerController controller) {
    final value = controller.value;
    final ratio = value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;
    return AspectRatio(
      aspectRatio: ratio,
      child: GestureDetector(
        key: _videoKey,
        behavior: HitTestBehavior.opaque,
        onTap: _onTapVideo,
        onDoubleTapDown: (details) => _doubleTapX = details.localPosition.dx,
        onDoubleTap: () {
          final width = _videoKey.currentContext?.size?.width ?? 0;
          _seekBy((_doubleTapX ?? 0) < width / 2 ? -10 : 10);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(controller),
            if (value.isBuffering)
              const Center(
                child: CupertinoActivityIndicator(color: CupertinoColors.white),
              ),
            if (_showControls || !value.isPlaying)
              Container(color: CupertinoColors.black.withValues(alpha: 0.12)),
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayPause,
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: value.isPlaying
                      ? null
                      : const Icon(
                          CupertinoIcons.play_fill,
                          color: CupertinoColors.white,
                          size: 42,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(
    VideoPlayerController controller,
    double positionSeconds,
    double durationSeconds,
  ) => Container(
    padding: const EdgeInsets.fromLTRB(12, 16, 12, 2),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          CupertinoColors.black.withValues(alpha: 0),
          CupertinoColors.black.withValues(alpha: 0.82),
        ],
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              onPressed: _togglePlayPause,
              child: Icon(
                controller.value.isPlaying
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                color: CupertinoColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _time(
                Duration(
                  milliseconds: ((_scrubSeconds ?? positionSeconds) * 1000)
                      .round(),
                ),
              ),
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              _time(controller.value.duration, roundUp: true),
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 11,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.only(left: 8),
              minimumSize: const Size(34, 32),
              onPressed: () {
                _isMuted = !_isMuted;
                controller.setVolume(_isMuted ? 0 : 1);
                setState(() {});
                _scheduleHide();
              },
              child: Icon(
                _isMuted ? CupertinoIcons.volume_off : CupertinoIcons.volume_up,
                color: CupertinoColors.white,
                size: 18,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.only(left: 4),
              minimumSize: const Size(38, 32),
              onPressed: _chooseSpeed,
              child: Text(
                '$_speed×',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        _buildTimeline(durationSeconds, positionSeconds),
      ],
    ),
  );

  Widget _buildTimeline(double durationSeconds, double positionSeconds) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final position = (_scrubSeconds ?? positionSeconds).clamp(
            0.0,
            durationSeconds,
          );
          final progress = durationSeconds > 0
              ? position / durationSeconds
              : 0.0;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _updateScrub(
              details.localPosition.dx,
              constraints.maxWidth,
              durationSeconds,
            ),
            onTapUp: (_) => _commitScrub(),
            onTapCancel: () {
              if (_scrubSeconds != null) setState(() => _scrubSeconds = null);
            },
            onHorizontalDragStart: (details) => _updateScrub(
              details.localPosition.dx,
              constraints.maxWidth,
              durationSeconds,
            ),
            onHorizontalDragUpdate: (details) => _updateScrub(
              details.localPosition.dx,
              constraints.maxWidth,
              durationSeconds,
            ),
            onHorizontalDragEnd: (_) => _commitScrub(),
            child: SizedBox(
              height: 32,
              width: double.infinity,
              child: CustomPaint(painter: _VideoTimelinePainter(progress)),
            ),
          );
        },
      );

  Widget _buildLoading() => Stack(
    fit: StackFit.expand,
    children: [
      if (widget.placeholderUrl != null)
        CachedNetworkImage(
          imageUrl: widget.placeholderUrl!,
          fit: BoxFit.contain,
          errorWidget: (_, _, _) => const SizedBox.shrink(),
        ),
      const Center(
        child: CupertinoActivityIndicator(
          radius: 16,
          color: CupertinoColors.white,
        ),
      ),
    ],
  );

  Widget _buildError() => CupertinoButton(
    onPressed: _initializeVideo,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.refresh, color: AppColors.errorRed, size: 36),
        const SizedBox(height: 8),
        Text(
          'Не удалось воспроизвести. Повторить',
          style: TextStyle(color: AppColors.white),
        ),
      ],
    ),
  );
}

class _VideoTimelinePainter extends CustomPainter {
  const _VideoTimelinePainter(this.progress);

  static const double thumbRadius = 13;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final start = thumbRadius;
    final end = size.width - thumbRadius;
    if (end <= start) return;
    final y = size.height / 2;
    final thumbX = start + (end - start) * progress.clamp(0.0, 1.0);
    final track = Paint()
      ..color = CupertinoColors.white.withValues(alpha: 0.78)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final played = Paint()
      ..color = CupertinoColors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(start, y), Offset(end, y), track);
    canvas.drawLine(Offset(start, y), Offset(thumbX, y), played);
    canvas.drawCircle(
      Offset(thumbX, y),
      thumbRadius,
      Paint()..color = CupertinoColors.white,
    );
    canvas.drawCircle(
      Offset(thumbX, y),
      6,
      Paint()..color = const Color(0xFF222126),
    );
  }

  @override
  bool shouldRepaint(covariant _VideoTimelinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

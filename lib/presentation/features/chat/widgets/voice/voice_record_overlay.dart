import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/features/chat/utils/audio_duration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum _DragState { none, cancel, lock }

class VoiceRecordOverlay extends StatefulWidget {
  final ValueChanged<({File file, double durationSeconds})> onSend;
  final VoidCallback onCancel;
  final ValueChanged<bool>? onLock;

  const VoiceRecordOverlay({
    super.key,
    required this.onSend,
    required this.onCancel,
    this.onLock,
  });

  @override
  VoiceRecordOverlayState createState() => VoiceRecordOverlayState();
}

class VoiceRecordOverlayState extends State<VoiceRecordOverlay>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecord = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _timer;
  int _recordSeconds = 0;
  bool _isLocked = false;
  _DragState _dragState = _DragState.none;
  bool _showLockIndicator = false;
  bool _showCancelIndicator = false;

  Offset? _startDragPosition;
  double _dragOffsetX = 0.0;
  double _dragOffsetY = 0.0;

  final List<double> _audioLevels = List.generate(50, (_) => 0.0);

  late AnimationController _slideCancelController;
  late Animation<Offset> _slideCancelAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: AppColors.transparent,
          statusBarColor: AppColors.transparent,
        ),
      );
    });

    _slideCancelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideCancelAnimation =
        Tween<Offset>(
          begin: const Offset(0.2, 0),
          end: const Offset(0.0, 0),
        ).animate(
          CurvedAnimation(
            parent: _slideCancelController,
            curve: Curves.easeOut,
          ),
        );

    _startRecording();
    _startTimer();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecord.hasPermission()) {
        final Directory tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecord.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        _startAmplitudeListener();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Ошибка начала записи: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordSeconds++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startAmplitudeListener() {
    _amplitudeSubscription = _audioRecord
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
          if (mounted) {
            setState(() {
              const minDb = -120.0;
              const maxDb = 0.0;
              final db = amp.current;
              final clampedDb = db.clamp(minDb, maxDb);
              final normalized = (clampedDb - minDb) / (maxDb - minDb);

              _audioLevels.add(normalized);
              if (_audioLevels.length > 50) {
                _audioLevels.removeAt(0);
              }
            });
          }
        });
  }

  Future<String?> _stopRecording() async {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();

    try {
      if (await _audioRecord.isRecording()) {
        final result = await _audioRecord.stop();
        if (result != null && result.isNotEmpty) {
          return result;
        }
        debugPrint('Ошибка: запись вернула пустой результат');
      }
    } catch (e) {
      debugPrint('Ошибка остановки записи: $e');
    }
    return null;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // 🎯 ПУБЛИЧНЫЕ МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ ИЗВНЕ

  void startDrag(Offset localPosition) {
    _startDragPosition = localPosition;
    setState(() {
      _dragOffsetX = 0.0;
      _dragOffsetY = 0.0;
      _dragState = _DragState.none;
      _showLockIndicator = false;
      _showCancelIndicator = false;
    });
  }

  void updateDrag(Offset localPosition) {
    if (_startDragPosition == null) {
      _startDragPosition = localPosition;
      setState(() {
        _dragOffsetX = 0.0;
        _dragOffsetY = 0.0;
      });
      return;
    }

    setState(() {
      _dragOffsetX = localPosition.dx - _startDragPosition!.dx;
      _dragOffsetY = localPosition.dy - _startDragPosition!.dy;

      if (_dragOffsetX < -60) {
        if (_dragState != _DragState.cancel) {
          _dragState = _DragState.cancel;
          _showCancelIndicator = true;
          _showLockIndicator = false;
          _slideCancelController.forward();
        }
      } else {
        if (_dragState == _DragState.cancel) {
          _dragState = _DragState.none;
          _showCancelIndicator = false;
          _slideCancelController.reverse();
        }

        if (_dragOffsetY < -80) {
          if (_dragState != _DragState.lock) {
            _dragState = _DragState.lock;
            _showLockIndicator = true;
          }
        } else {
          if (_dragState == _DragState.lock) {
            _dragState = _DragState.none;
            _showLockIndicator = false;
          }
        }
      }
    });
  }

  void endDrag() {
    _startDragPosition = null;
    if (_isLocked) return;

    if (_dragState == _DragState.lock) {
      setState(() {
        _isLocked = true;
      });
      widget.onLock?.call(true);
      return;
    }

    if (_dragState == _DragState.cancel) {
      _handleCancel();
    } else {
      send();
    }

    if (mounted) {
      setState(() {
        _showLockIndicator = false;
        _showCancelIndicator = false;
        _dragState = _DragState.none;
      });
    }
  }

  void cancelDrag() {
    _startDragPosition = null;
    _handleCancel();
  }

  void send() async {
    final path = await _stopRecording();
    if (path != null) {
      final file = File(path);
      final durationSeconds = await AudioDuration.getDurationInSeconds(file);
      widget.onSend((file: file, durationSeconds: durationSeconds));
    } else {
      widget.onCancel();
    }
  }

  void _handleCancel() async {
    await _stopRecording();
    widget.onCancel();
  }

  void _handleLockToggle() {
    setState(() {
      _isLocked = !_isLocked;
    });
    widget.onLock?.call(_isLocked);
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: AppColors.transparent,
        statusBarColor: AppColors.transparent,
      ),
    );
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    _audioRecord.dispose();
    _slideCancelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLocked ? _buildLockedUI(context) : _buildRecordingUI(context);
  }

  Widget _buildRecordingUI(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: CircularTopNotchClipper(),
          child: Container(
            height: 100,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: AppColors.blurple,
            child: Padding(
              padding: const EdgeInsets.only(top: 35),
              child: Row(
                children: [
                  const SizedBox(width: 5),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        AnimatedOpacity(
                          opacity: _showCancelIndicator ? 1.0 : 0.6,
                          duration: const Duration(milliseconds: 200),
                          child: SlideTransition(
                            position: _slideCancelAnimation,
                            child: Icon(
                              CupertinoIcons.back,
                              color: AppColors.onBlurple,
                              size: 16,
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: _showCancelIndicator ? 1.0 : 0.6,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            CupertinoIcons.delete,
                            color: AppColors.onBlurple,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(_recordSeconds),
                            style: AppText.mediumTextStyle.copyWith(
                              color: AppColors.onBlurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: _buildWaveform()),
                        ],
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    minSize: 0,
                    onPressed: send,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.up_arrow,
                        color: AppColors.onBlurple,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showLockIndicator)
          Positioned(
            right: 20,
            bottom: 85,
            child: GestureDetector(
              onTap: _handleLockToggle,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.up_arrow,
                      color: AppColors.onBlurple,
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      CupertinoIcons.lock,
                      color: AppColors.onBlurple,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Positioned(
            right: 20,
            bottom: 80,
            child: GestureDetector(
              onTap: _handleLockToggle,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.up_arrow,
                      color: AppColors.onBlurple,
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      CupertinoIcons.lock_open,
                      color: AppColors.onBlurple,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_dragState != _DragState.none)
          Positioned(
            top: 25,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _dragState == _DragState.cancel
                    ? 'Отменить запись'
                    : 'Заблокировать',
                style: AppText.mediumTextStyle.copyWith(
                  color: AppColors.onBlurple,
                ),
              ),
            ),
          ),
        if (_dragState == _DragState.none)
          Positioned(
            top: 25,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Отпустите, чтобы отправить",
                style: AppText.mediumTextStyle.copyWith(
                  color: AppColors.onBlurple,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLockedUI(BuildContext context) {
    return ClipPath(
      clipper: CircularTopNotchClipper(),
      child: Container(
        height: 100,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        color: AppColors.blurple,
        child: Padding(
          padding: const EdgeInsets.only(top: 35),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.all(6),
                minSize: 0,
                onPressed: _handleCancel,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.delete,
                    color: AppColors.onBlurple,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(_recordSeconds),
                        style: AppText.mediumTextStyle.copyWith(
                          color: AppColors.onBlurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: _buildWaveform()),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                minSize: 0,
                onPressed: send,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.up_arrow,
                    color: AppColors.onBlurple,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const barWidth = 2.5;
        const spacing = 1.0;
        const totalBarSpace = barWidth + spacing;
        final maxBars = (availableWidth / totalBarSpace).floor();
        final barsToShow = min(_audioLevels.length, max(10, maxBars));

        List<double> displayedLevels;
        if (barsToShow < _audioLevels.length) {
          displayedLevels = [];
          final step = _audioLevels.length / barsToShow;
          for (int i = 0; i < barsToShow; i++) {
            final index = (i * step).floor();
            displayedLevels.add(_audioLevels[index]);
          }
        } else {
          displayedLevels = _audioLevels.sublist(0, barsToShow);
        }

        return SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: displayedLevels
                .map(
                  (level) => Container(
                    width: barWidth,
                    height: max(2.0, 30 * level),
                    decoration: BoxDecoration(
                      color: AppColors.onBlurple.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class CircularTopNotchClipper extends CustomClipper<Path> {
  final double notchDepth;
  final double cornerHeight;

  CircularTopNotchClipper({this.notchDepth = 30, this.cornerHeight = 40});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, cornerHeight);
    path.cubicTo(
      size.width * 0.1,
      cornerHeight - notchDepth,
      size.width * 0.9,
      cornerHeight - notchDepth,
      size.width,
      cornerHeight,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return oldClipper is CircularTopNotchClipper &&
        (oldClipper.notchDepth != notchDepth ||
            oldClipper.cornerHeight != cornerHeight);
  }
}

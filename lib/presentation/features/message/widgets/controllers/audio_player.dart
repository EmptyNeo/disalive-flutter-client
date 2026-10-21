// lib/presentation/features/message/widgets/audio_player.dart
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Простой аудио-плеер: кнопка play/pause + прогресс-бар (трек, заливка,
/// бегунок — без waveform/индикации громкости) + время. Перемотка — тапом
/// или перетаскиванием бегунка по бару.
class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({
    super.key,
    required this.url,
    required this.duration,
    this.isMine = false,
  });

  final String url;

  /// Длительность в секундах (FileMessage.duration) — используется как
  /// длина трека сразу, пока сам плеер не сообщит свою (обычно совпадает).
  final double duration;
  final bool isMine;

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  static _AudioPlayerWidgetState? _activePlayer;
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;

  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  late Duration _duration;

  // Пока бегунок тащат — не даём позиции из стрима плеера перебивать то,
  // что в этот момент показывается пользователю.
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    _duration = Duration(milliseconds: (widget.duration * 1000).round());

    _positionSub = _player.onPositionChanged.listen((position) {
      if (_isSeeking || !mounted) return;
      setState(() => _position = position);
    });
    _durationSub = _player.onDurationChanged.listen((duration) {
      if (!mounted || duration.inMilliseconds == 0) return;
      setState(() => _duration = duration);
    });
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playerState = state);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    if (identical(_activePlayer, this)) _activePlayer = null;
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  bool get _isPlaying => _playerState == PlayerState.playing;

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      if (identical(_activePlayer, this)) _activePlayer = null;
      if (mounted) setState(() => _playerState = PlayerState.paused);
    } else {
      final previous = _activePlayer;
      if (previous != null && !identical(previous, this)) {
        await previous._pauseForAnotherPlayer();
      }
      _activePlayer = this;
      if (mounted) setState(() => _playerState = PlayerState.playing);
      await _player.play(UrlSource(widget.url), position: _position);
    }
  }

  Future<void> _pauseForAnotherPlayer() async {
    await _player.pause();
    if (mounted) setState(() => _playerState = PlayerState.paused);
  }

  void _onSeekStart(double fraction) {
    _isSeeking = true;
    _updatePositionFromFraction(fraction);
  }

  void _onSeekUpdate(double fraction) {
    _updatePositionFromFraction(fraction);
  }

  void _onSeekEnd() {
    _player.seek(_position);
    _isSeeking = false;
  }

  void _updatePositionFromFraction(double fraction) {
    if (_duration.inMilliseconds == 0) return;
    final clamped = fraction.clamp(0.0, 1.0);
    setState(() {
      _position = Duration(
        milliseconds: (_duration.inMilliseconds * clamped).round(),
      );
    });
  }

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$ss';
    }
    return '$minutes:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isMine ? AppColors.onBlurple : AppColors.blurple;
    final trackColor = accent.withValues(alpha: 0.25);
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

    // В покое/паузе показываем оставшуюся длительность целиком, во время
    // проигрывания — текущую позицию.
    final timeToShow = _isPlaying || _position != Duration.zero
        ? _position
        : _duration;

    return Row(
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Icon(
            _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
            size: 30,
            color: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ProgressBar(
            progress: progress,
            color: accent,
            trackColor: trackColor,
            onSeekStart: _onSeekStart,
            onSeekUpdate: _onSeekUpdate,
            onSeekEnd: _onSeekEnd,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(timeToShow),
          style: AppText.lowTextStyle.copyWith(
            color: widget.isMine
                ? AppColors.onBlurple.withValues(alpha: 0.75)
                : AppColors.greyple,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Трек + заливка + бегунок. Тап — сразу перемотка в эту точку,
/// перетаскивание — live-обновление позиции с сиком по окончании жеста.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.onSeekStart,
    required this.onSeekUpdate,
    required this.onSeekEnd,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekUpdate;
  final VoidCallback onSeekEnd;

  double _fractionFromLocalX(double localX, double width) {
    if (width <= 0) return 0;
    return (localX / width).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            onSeekStart(_fractionFromLocalX(details.localPosition.dx, width));
            onSeekEnd();
          },
          onHorizontalDragStart: (details) =>
              onSeekStart(_fractionFromLocalX(details.localPosition.dx, width)),
          onHorizontalDragUpdate: (details) => onSeekUpdate(
            _fractionFromLocalX(details.localPosition.dx, width),
          ),
          onHorizontalDragEnd: (_) => onSeekEnd(),
          child: SizedBox(
            height: 20,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(2 * progress - 1, 0),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

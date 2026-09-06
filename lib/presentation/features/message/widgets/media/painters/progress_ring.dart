import 'package:disalive/presentation/features/message/widgets/media/painters/ring_painter.dart';
import 'package:flutter/cupertino.dart';

/// Кольцевой прогресс без зависимости от Material (в проекте только
/// Cupertino) — рисуется вручную через CustomPainter. progress == null —
/// неопределённый прогресс (крутится, пока не пришёл Content-Length).
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.progress, required this.color});

  final double? progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (progress == null)
            const CupertinoActivityIndicator(radius: 8)
          else
            CustomPaint(
              size: const Size(28, 28),
              painter: RingPainter(progress: progress!, color: color),
            ),
          Icon(CupertinoIcons.xmark, size: 10, color: color),
        ],
      ),
    );
  }
}

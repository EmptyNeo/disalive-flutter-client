import 'package:flutter/cupertino.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/user_status.dart';

class StatusDot extends StatelessWidget {
  final UserStatus status;
  final double size;
  final Color? backgroundColor;

  const StatusDot({
    super.key,
    required this.status,
    required this.size,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Если статус "Неактивен", рисуем настоящий полумесяц через CustomPaint
    if (status == UserStatus.idle) {
      return CustomPaint(
        size: Size(size, size),
        painter: _MoonPainter(color: status.color),
      );
    }

    // Если статус "Не в сети" — вырезаем маленький круг посередине
    if (status == UserStatus.offline) {
      return CustomPaint(
        size: Size(size, size),
        painter: _OfflinePainter(color: status.color),
      );
    }

    // Для остальных статусов используем обычные контейнеры
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
      child: status == UserStatus.dnd
          ? Center(
              child: Container(
                width: size * 0.5,
                height: size * 0.15,
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            )
          : null, // Online (пустой зеленый круг)
    );
  }
}

// Художник для offline — серый круг с вырезанным маленьким кругом
class _OfflinePainter extends CustomPainter {
  final Color color;

  _OfflinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double s = size.width;

    // Основной круг
    final mainPath = Path()..addOval(Rect.fromLTWH(0, 0, s, s));

    // Маленький вырезанный круг по центру
    final cutRadius = s * 0.2; // Очень маленький
    final cutCenter = Offset(s / 2, s / 2);
    final cutPath = Path()
      ..addOval(Rect.fromCircle(center: cutCenter, radius: cutRadius));

    // Вычитаем маленький круг из основного
    final offlinePath = Path.combine(
      PathOperation.difference,
      mainPath,
      cutPath,
    );

    canvas.drawPath(offlinePath, paint);
  }

  @override
  bool shouldRepaint(covariant _OfflinePainter oldDelegate) =>
      color != oldDelegate.color;
}

// Художник, который математически ровно вырезает полумесяц
class _MoonPainter extends CustomPainter {
  final Color color;

  _MoonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double s = size.width;

    final mainPath = Path()..addOval(Rect.fromLTWH(0, 0, s, s));

    final cutPath = Path()
      ..addOval(Rect.fromLTWH(-s * 0.15, -s * 0.15, s * 0.85, s * 0.85));

    final moonPath = Path.combine(PathOperation.difference, mainPath, cutPath);

    canvas.drawPath(moonPath, paint);
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) =>
      color != oldDelegate.color;
}

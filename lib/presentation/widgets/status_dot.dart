// lib/presentation/widgets/status_dot.dart
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
    final bg = backgroundColor ?? AppColors.mainBackground;

    // Если статус "Неактивен", рисуем настоящий полумесяц через CustomPaint
    if (status == UserStatus.idle) {
      return CustomPaint(
        size: Size(size, size),
        painter: _MoonPainter(color: status.color),
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
                width: size * 0.6,
                height: size * 0.15,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            )
          : status == UserStatus.offline
          ? Center(
              child: Container(
                width: size * 0.45,
                height: size * 0.45,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              ),
            )
          : null, // Online (пустой зеленый круг)
    );
  }
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

    // 1. Создаем контур основного круга
    final mainPath = Path()..addOval(Rect.fromLTWH(0, 0, s, s));

    // 2. Создаем контур "вырезающего" круга (сдвинут влево и вверх)
    final cutPath = Path()
      ..addOval(Rect.fromLTWH(-s * 0.15, -s * 0.15, s * 0.85, s * 0.85));

    // 3. Вычитаем второй контур из первого
    final moonPath = Path.combine(PathOperation.difference, mainPath, cutPath);

    // Рисуем результат
    canvas.drawPath(moonPath, paint);
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) =>
      color != oldDelegate.color;
}

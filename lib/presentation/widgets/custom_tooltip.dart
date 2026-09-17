// presentation/widgets/custom_tooltip.dart
import 'dart:ui';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

enum TooltipPosition { top, bottom }

/// Тултип по тапу — Cupertino-аналог Material Tooltip, без самого
/// Material. Тап по [child] показывает [title]/[subtitle] (или
/// произвольный [builder]) рядом с ним; поверх экрана встаёт прозрачный
/// барьер, блокирующий всё под тултипом — тап по барьеру его закрывает.
///
/// Позиционирование максимально простое: считаем глобальный Rect таргета
/// через RenderBox один раз при показе и кладём тултип рядом через
/// Positioned + FractionalTranslation (сдвиг на половину СВОЕЙ ширины/
/// высоты уже после layout) — без LayerLink, без слежения за скроллом.
class CustomTooltip extends StatefulWidget {
  const CustomTooltip({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.builder,
    this.position = TooltipPosition.top,
    this.maxWidth = 240,
  }) : assert(
         title != null || builder != null,
         'Нужен либо title, либо builder',
       );

  final Widget child;
  final String? title;
  final String? subtitle;
  final WidgetBuilder? builder;
  final TooltipPosition position;
  final double maxWidth;

  @override
  State<CustomTooltip> createState() => _CustomTooltipState();
}

class _CustomTooltipState extends State<CustomTooltip>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );

  @override
  void dispose() {
    _removeEntry();
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_entry != null) {
      _hideTooltip();
    } else {
      _showTooltip();
    }
  }

  void _showTooltip() {
    if (!mounted) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final offset = box.localToGlobal(Offset.zero);
    final targetCenterX = offset.dx + (box.size.width / 2);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // 🎯 1. Умный расчет позиции с учетом краев экрана
    final halfWidth = widget.maxWidth / 2;
    final idealLeft = targetCenterX - halfWidth;
    // Не даем тултипу уйти за края экрана (отступ 16px)
    final safeLeft = idealLeft.clamp(
      16.0,
      screenWidth - widget.maxWidth - 16.0,
    );

    // 🎯 2. Вычисляем, где должен быть уголочек относительно левого края тултипа
    final caretOffsetX = targetCenterX - safeLeft;

    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hideTooltip,
              child: Container(
                color: CupertinoColors.transparent,
              ),
            ),
          ),
          Builder(
            builder: (ctx) {
              final bottomPosition = screenHeight - offset.dy + 8;

              return Positioned(
                left: safeLeft,
                bottom: bottomPosition,
                child: FadeTransition(
                  opacity: _controller,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: _TooltipBubble(
                      maxWidth: widget.maxWidth,
                      isAboveTarget: widget.position == TooltipPosition.top,
                      caretOffsetX: caretOffsetX, // 🎯 Передаем смещение
                      child: widget.builder != null
                          ? Builder(builder: widget.builder!)
                          : _DefaultTooltipContent(
                              title: widget.title!,
                              subtitle: widget.subtitle,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
    _controller.forward(from: 0);
  }

  Future<void> _hideTooltip() async {
    if (_entry == null) return;
    await _controller.reverse();
    _removeEntry();
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}

class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble({
    required this.child,
    required this.maxWidth,
    required this.isAboveTarget,
    required this.caretOffsetX, // 🎯 Новый параметр
  });

  final Widget child;
  final double maxWidth;
  final bool isAboveTarget;
  final double caretOffsetX;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    // 🎯 Используем Stack вместо Column, чтобы абсолютно позиционировать уголочек
    // clipBehavior: Clip.none позволяет уголочку выходить за границы borderRadius пузыря
    return Stack(
      clipBehavior: Clip.none,
      children: [
        bubble,

        // Если тултип СВЕРХУ цели, уголочек должен быть СНИЗУ пузыря и указывать ВНИЗ
        if (isAboveTarget)
          Positioned(
            bottom: -6,
            // Высота уголочка
            left: caretOffsetX - 6,
            // Центрируем 12px уголочек относительно targetCenterX
            child: _buildCaret(pointingUp: false),
          )
        // Если тултип СНИЗУ цели, уголочек должен быть СВЕРХУ пузыря и указывать ВВЕРХ
        else
          Positioned(
            top: -6,
            left: caretOffsetX - 6,
            child: _buildCaret(pointingUp: true),
          ),
      ],
    );
  }

  Widget _buildCaret({required bool pointingUp}) {
    return CustomPaint(
      size: const Size(12, 6),
      painter: _CaretPainter(
        pointingUp: pointingUp,
        color: AppColors.glassPanelBottom,
      ),
    );
  }
}

class _CaretPainter extends CustomPainter {
  const _CaretPainter({required this.pointingUp, required this.color});

  final bool pointingUp;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointingUp) {
      // Уголочек указывает вверх (для тултипа, который находится ПОД целью)
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      // Уголочек указывает вниз (для тултипа, который находится НАД целью)
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.96));
  }

  @override
  bool shouldRepaint(covariant _CaretPainter oldDelegate) =>
      oldDelegate.pointingUp != pointingUp || oldDelegate.color != color;
}

class _DefaultTooltipContent extends StatelessWidget {
  const _DefaultTooltipContent({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.mediumTextStyle.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppText.lowTextStyle.copyWith(color: AppColors.greyple),
          ),
        ],
      ],
    );
  }
}

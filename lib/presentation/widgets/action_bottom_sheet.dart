// presentation/widgets/action_bottom_sheet.dart
import 'dart:ui';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:flutter/cupertino.dart';

/// Всплывающее меню действий в Glassmorphism-стиле — блюр + полупрозрачный
/// градиент из [AppColors.glassPanelTop]/[AppColors.glassPanelBottom],
/// плавающая карточка с отступами от краёв экрана (не прилипает к низу).
///
/// Закрывается тапом по грабберу и его протягиванием вниз: не дотянул до
/// порога — карточка плавно возвращается на место, дотянул (или дёрнул
/// достаточно резко) — доезжает вниз и закрывается. Отдельной кнопки
/// отмены больше нет — грабер её полностью заменяет.
class ActionBottomSheet extends StatefulWidget {
  const ActionBottomSheet({super.key, this.title, required this.actions});

  final String? title;
  final List<ActionItem> actions;

  static Future<void> show(
    BuildContext context, {
    String? title,
    required List<ActionItem> actions,
  }) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => ActionBottomSheet(title: title, actions: actions),
    );
  }

  @override
  State<ActionBottomSheet> createState() => _ActionBottomSheetState();
}

class _ActionBottomSheetState extends State<ActionBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;

  double _dragExtent = 0;

  static const double _dismissDistance = 120;
  static const double _dismissVelocity = 700;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleGrabberDragUpdate(DragUpdateDetails details) {
    // Тянуть вверх выше исходной позиции нельзя — карточка не "прыгает"
    // выше своего места в разложенном виде.
    if (_dragExtent <= 0 && details.delta.dy < 0) return;
    setState(() {
      _dragExtent = (_dragExtent + details.delta.dy).clamp(0, 600);
    });
  }

  void _handleGrabberDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragExtent > _dismissDistance || velocity > _dismissVelocity) {
      _dismiss();
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    final animation = Tween<double>(begin: _dragExtent, end: 0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    void listener() => setState(() => _dragExtent = animation.value);
    animation.addListener(listener);
    _slideController
        .forward(from: 0)
        .whenComplete(() => animation.removeListener(listener));
  }

  // Довозим карточку своим Transform полностью за экран и только потом
  // вызываем pop — иначе встроенная exit-анимация showCupertinoModalPopup
  // стартует с нулевого смещения поверх уже сдвинутой карточки, и получается
  // рывок. Так к моменту pop() карточки уже не видно, и он проходит незаметно.
  void _dismiss() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final animation = Tween<double>(
      begin: _dragExtent,
      end: screenHeight,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeIn));
    void listener() => setState(() => _dragExtent = animation.value);
    animation.addListener(listener);
    _slideController.forward(from: 0).whenComplete(() {
      animation.removeListener(listener);
      if (mounted) {
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _dragExtent),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SafeArea(
          top: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _handleGrabberDragUpdate,
            onVerticalDragEnd: _handleGrabberDragEnd,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.glassPanelTop,
                      AppColors.glassPanelBottom,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: CupertinoColors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGrabber(),
                    if (widget.title != null) _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final action in widget.actions)
                            _buildActionTile(context, action),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Чисто визуальная подсказка — сам жест теперь ловится на всей карточке
  // в build(), не только тут, чтобы можно было свайпнуть вниз откуда угодно.
  Widget _buildGrabber() {
    return const Padding(
      padding: EdgeInsets.only(top: 10, bottom: 8),
      child: Center(child: _GrabberHandle()),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        // Было: CrossAxisAlignment.start
        children: [
          Container(
            width: 3,
            // Убираем margin, теперь line само центрируется
            decoration: BoxDecoration(
              color: AppColors.blurple,
              borderRadius: BorderRadius.circular(2),
            ),
            constraints: const BoxConstraints(minHeight: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.title != null)
                  Text(
                    widget.title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.lowTextStyle.copyWith(
                      color: AppColors.greyple,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, ActionItem action) {
    final color =
        action.color ??
        (action.isDestructive ? CupertinoColors.systemRed : AppColors.white);

    return _PressableRow(
      onTap: () {
        Navigator.pop(context);
        action.onTap?.call();
      },
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(action.icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              action.label,
              style: AppText.mediumTextStyle.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Полоска-граббер вынесена отдельным виджетом — используется только как
/// визуальная подсказка, сам жест теперь общий на всю карточку.
class _GrabberHandle extends StatelessWidget {
  const _GrabberHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// Строка действия с собственной подсветкой при нажатии
/// ([AppColors.glassPanelPressed]) — CupertinoButton такого без принудительно
/// всегда залитого фона не умеет.
class _PressableRow extends StatefulWidget {
  const _PressableRow({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableRow> createState() => _PressableRowState();
}

class _PressableRowState extends State<_PressableRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.98 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.glassPanelPressed.withValues(alpha: 0.6)
                : CupertinoColors.transparent,
            borderRadius: BorderRadius.circular(32),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

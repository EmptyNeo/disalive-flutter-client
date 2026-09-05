// presentation/features/media/media_viewer_route.dart
import 'package:disalive/domain/enums/ui/media_close_mode.dart';
import 'package:flutter/cupertino.dart';

/// PageRoute с ручной анимацией "разворачивания" вложения из прямоугольника
/// сообщения на весь экран и сворачивания обратно.
///
/// Не использует Hero: Hero сам решает, куда лететь при pop (ищет виджет с
/// тем же тегом в подложке), а нам нужно самим выбирать между "лететь точно
/// в источник" и "просто уехать вверх/вниз" в рамках одного и того же
/// закрытия — в зависимости от того, сменилось ли сообщение во время
/// свайпа. Экран выставляет это через [closeMode] непосредственно перед
/// вызовом pop.
class MediaViewerRoute<T> extends PageRoute<T> {
  MediaViewerRoute({
    required this.builder,
    required this.sourceRect,
    super.settings,
  });

  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    void Function(MediaCloseMode mode) setCloseMode,
  )
  builder;

  /// Глобальные координаты вложения, из которого открываем экран.
  final Rect sourceRect;

  MediaCloseMode closeMode = MediaCloseMode.toSource;

  static Future<T?> open<T>(
    BuildContext context, {
    required Rect sourceRect,
    required Widget Function(
      BuildContext context,
      Animation<double> animation,
      void Function(MediaCloseMode mode) setCloseMode,
    )
    builder,
  }) {
    return Navigator.of(
      context,
    ).push<T>(MediaViewerRoute<T>(sourceRect: sourceRect, builder: builder));
  }

  // opaque: false — чат под вьюером продолжает рисоваться, иначе во время
  // разворачивания/схлопывания за пределами прямоугольника будет чёрный
  // фон вместо реального чата.
  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => CupertinoColors.black;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 320);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 280);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context, animation, (mode) => closeMode = mode);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final screenSize = MediaQuery.sizeOf(context);
    final fullscreenRect = Offset.zero & screenSize;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final isClosing = controller!.status == AnimationStatus.reverse;

        Rect targetRect;
        double opacity = 1;

        if (!isClosing || closeMode == MediaCloseMode.toSource) {
          // Открытие — всегда от sourceRect. Либо закрытие точно назад,
          // если сообщение во время просмотра не сменилось.
          targetRect = Rect.lerp(sourceRect, fullscreenRect, animation.value)!;
        } else {
          // Схлопывание "в никуда" — едем за пределы экрана вверх/вниз,
          // одновременно сжимаясь и растворяясь.
          final travel = screenSize.height * 0.6 * (1 - animation.value);
          final dy = closeMode == MediaCloseMode.collapseUp ? -travel : travel;
          final scale = 0.6 + 0.4 * animation.value;
          targetRect = Rect.fromCenter(
            center: fullscreenRect.center.translate(0, dy),
            width: screenSize.width * scale,
            height: screenSize.height * scale,
          );
          opacity = animation.value;
        }

        return SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: targetRect,
                child: Opacity(opacity: opacity.clamp(0, 1), child: child),
              ),
            ],
          ),
        );
      },
    );
  }
}

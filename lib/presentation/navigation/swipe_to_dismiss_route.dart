// lib/presentation/navigation/swipe_to_dismiss_route.dart
import 'package:flutter/cupertino.dart';

/// PageRoute, который открывается поверх текущего экрана и поддерживает
/// интерактивный свайп слева направо для закрытия — экран уезжает вправо,
/// под ним видно то, что было открыто раньше (как закрытие чата в Telegram).
///
/// Не привязан к конкретному экрану: чтобы получить это поведение для
/// любого другого экрана, достаточно вызвать [SwipeToDismissRoute.push].
///
/// Технически: маршрут неопаковый ([opaque] = false), поэтому предыдущий
/// экран остаётся отрисованным под этим, а перетаскивание вручную двигает
/// [AnimationController] самого роута — тот же приём, которым Cupertino
/// реализует системный back-swipe, только без привязки к краю экрана.
class SwipeToDismissRoute<T> extends PageRoute<T> {
  SwipeToDismissRoute({
    required this.builder,
    this.dismissThreshold = 0.35,
    this.edgeStartOffset,
    super.settings,
  });

  /// Билдер содержимого экрана.
  final WidgetBuilder builder;

  /// Доля ширины экрана, после которой отпущенный жест закрывает экран.
  final double dismissThreshold;

  /// Если задано — жест засчитывается, только если начался не дальше этого
  /// отступа от левого края (как системный back-swipe на iOS).
  /// null (по умолчанию) — жест работает из любой точки экрана.
  final double? edgeStartOffset;

  /// Открывает [builder] поверх текущего экрана с этим поведением.
  static Future<T?> push<T>(
    BuildContext context,
    WidgetBuilder builder, {
    double dismissThreshold = 0.35,
    double? edgeStartOffset,
    RouteSettings? settings,
  }) {
    return Navigator.of(context).push<T>(
      SwipeToDismissRoute<T>(
        builder: builder,
        dismissThreshold: dismissThreshold,
        edgeStartOffset: edgeStartOffset,
        settings: settings,
      ),
    );
  }

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _SwipeToDismissGestureArea(
      route: this,
      child: Builder(builder: builder),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    );
  }
}

/// Ловит горизонтальный drag поверх содержимого экрана и вручную ведёт
/// AnimationController роута: animation == 1 — экран полностью открыт,
/// animation == 0 — полностью уехал вправо (можно закрывать).
class _SwipeToDismissGestureArea extends StatefulWidget {
  const _SwipeToDismissGestureArea({required this.route, required this.child});

  final SwipeToDismissRoute route;
  final Widget child;

  @override
  State<_SwipeToDismissGestureArea> createState() =>
      _SwipeToDismissGestureAreaState();
}

class _SwipeToDismissGestureAreaState
    extends State<_SwipeToDismissGestureArea> {
  bool _dragActive = false;

  void _handleDragStart(DragStartDetails details) {
    final edgeStartOffset = widget.route.edgeStartOffset;
    if (edgeStartOffset != null &&
        details.globalPosition.dx > edgeStartOffset) {
      _dragActive = false;
      return;
    }
    _dragActive = true;
    widget.route.navigator?.didStartUserGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragActive) return;
    final controller = widget.route.controller;
    if (controller == null) return;
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 0) return;
    // Свайп вправо (delta.dx > 0) уменьшает value — экран уезжает и
    // открывает то, что находится под ним.
    controller.value -= details.delta.dx / width;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragActive) return;
    _dragActive = false;

    final controller = widget.route.controller;
    final navigator = widget.route.navigator;
    if (controller == null || navigator == null) return;

    final width = MediaQuery.sizeOf(context).width;
    final velocity = width > 0 ? (details.primaryVelocity ?? 0) / width : 0.0;

    final passedThreshold =
        controller.value <= (1 - widget.route.dismissThreshold);
    final flingToDismiss = velocity > 0.7;
    final flingToStay = velocity < -0.7;
    final willDismiss = flingToStay
        ? false
        : (flingToDismiss || passedThreshold);

    if (willDismiss) {
      controller
          .animateBack(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          )
          .whenCompleteOrCancel(() {
            navigator.didStopUserGesture();
            if (navigator.mounted) navigator.pop();
          });
    } else {
      controller
          .animateTo(
            1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          )
          .whenCompleteOrCancel(navigator.didStopUserGesture);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: widget.child,
    );
  }
}

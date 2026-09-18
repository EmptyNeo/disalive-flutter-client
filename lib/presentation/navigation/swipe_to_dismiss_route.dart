import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

class SwipeToDismissRoute<T> extends PageRoute<T> {
  SwipeToDismissRoute({
    required this.builder,
    this.dismissThreshold = 0.35,
    this.edgeStartOffset,
    this.excludeKeys = const [],
    super.settings,
  });

  final WidgetBuilder builder;
  final double dismissThreshold;
  final double? edgeStartOffset;
  final List<GlobalKey> excludeKeys;

  static Future<T?> push<T>(
      BuildContext context,
      WidgetBuilder builder, {
        double dismissThreshold = 0.35,
        double? edgeStartOffset,
        RouteSettings? settings,
        List<GlobalKey> excludeKeys = const [],
      }) {
    return Navigator.of(context).push<T>(
      SwipeToDismissRoute<T>(
        builder: builder,
        dismissThreshold: dismissThreshold,
        edgeStartOffset: edgeStartOffset,
        settings: settings,
        excludeKeys: excludeKeys,
      ),
    );
  }

  // 🎯 Инкапсулированная логика работы с protected controller
  void updateDrag(double delta, double width) {
    if (controller != null) {
      controller!.value -= delta / width;
    }
  }

  void endDrag(double velocity, double width) {
    if (controller == null || navigator == null) return;

    final passedThreshold = controller!.value <= (1 - dismissThreshold);
    final flingToDismiss = velocity > 0.7;
    final flingToStay = velocity < -0.7;
    final willDismiss = flingToStay ? false : (flingToDismiss || passedThreshold);

    if (willDismiss) {
      controller!.animateBack(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      ).whenCompleteOrCancel(() {
        navigator!.didStopUserGesture();
        if (navigator!.mounted) navigator!.pop();
      });
    } else {
      controller!.animateTo(
        1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      ).whenCompleteOrCancel(navigator!.didStopUserGesture);
    }
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

class _SwipeToDismissGestureArea extends StatefulWidget {
  const _SwipeToDismissGestureArea({required this.route, required this.child});

  final SwipeToDismissRoute route;
  final Widget child;

  @override
  State<_SwipeToDismissGestureArea> createState() =>
      _SwipeToDismissGestureAreaState();
}

class _SwipeToDismissGestureAreaState extends State<_SwipeToDismissGestureArea> {
  bool _dragActive = false;
  bool? _isRightwardGesture;

  // Решает, годится ли эта точка касания для нашего свайпа — вызывается
  // распознавателем ДО того, как он вступает в gesture arena. Возврат
  // false означает, что мы для этого поинтера вообще не участвуем в
  // арене: дочерний виджет (слайдер, область кропа) получает жест как
  // единственный претендент, без конкуренции с нами.
  bool _isPointerAllowed(Offset globalPosition) {
    final edgeStartOffset = widget.route.edgeStartOffset;
    if (edgeStartOffset != null && globalPosition.dx > edgeStartOffset) {
      return false;
    }

    for (final key in widget.route.excludeKeys) {
      final keyContext = key.currentContext;
      if (keyContext == null) continue;
      final renderBox = keyContext.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) continue;
      final localPosition = renderBox.globalToLocal(globalPosition);
      if (renderBox.paintBounds.contains(localPosition)) {
        return false;
      }
    }

    return true;
  }

  void _handleDragStart(DragStartDetails details) {
    // exclude/edge уже отфильтрованы на уровне isPointerAllowed — сюда
    // долетают только разрешённые поинтеры.
    _isRightwardGesture = null;
    _dragActive = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isRightwardGesture == null) {
      _isRightwardGesture = details.delta.dx > 0;
      if (_isRightwardGesture!) {
        _dragActive = true;
        widget.route.navigator?.didStartUserGesture();
      } else {
        return;
      }
    }

    if (!_dragActive) return;
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 0) return;

    // 🎯 Вызываем публичный метод роута вместо прямого доступа к controller
    widget.route.updateDrag(details.delta.dx, width);
  }

  void _handleDragEnd(DragEndDetails details) {
    final wasActive = _dragActive;
    _dragActive = false;
    _isRightwardGesture = null;
    if (!wasActive) return;

    final width = MediaQuery.sizeOf(context).width;
    final velocity = width > 0 ? (details.primaryVelocity ?? 0) / width : 0.0;

    // 🎯 Вызываем публичный метод роута для завершения анимации
    widget.route.endDrag(velocity, width);
  }

  void _handleDragCancel() {
    final wasActive = _dragActive;
    _dragActive = false;
    _isRightwardGesture = null;
    if (wasActive) {
      widget.route.navigator?.didStopUserGesture();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        _ExcludeAwareHorizontalDragRecognizer:
        GestureRecognizerFactoryWithHandlers<
            _ExcludeAwareHorizontalDragRecognizer>(
              () => _ExcludeAwareHorizontalDragRecognizer(
            isAllowed: _isPointerAllowed,
          ),
              (instance) {
            instance
              ..onStart = _handleDragStart
              ..onUpdate = _handleDragUpdate
              ..onEnd = _handleDragEnd
              ..onCancel = _handleDragCancel;
          },
        ),
      },
      child: widget.child,
    );
  }
}

/// HorizontalDragGestureRecognizer, который для исключённых точек касания
/// (isAllowed возвращает false) вообще не подписывается на поинтер —
/// в отличие от проверки "внутри onDragStart", это происходит ДО входа в
/// gesture arena, так что дочерние виджеты в исключённой области получают
/// жест без конкуренции с нами.
class _ExcludeAwareHorizontalDragRecognizer
    extends HorizontalDragGestureRecognizer {
  _ExcludeAwareHorizontalDragRecognizer({required this.isAllowed});

  final bool Function(Offset globalPosition) isAllowed;

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (!isAllowed(event.position)) return false;
    return super.isPointerAllowed(event);
  }
}
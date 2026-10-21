import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Свайп-влево "ответить" (в духе WhatsApp/Telegram), без flutter_slidable:
/// весь жест — свой собственный, поэтому полностью контролируем и момент
/// срабатывания, и то, как выглядит индикатор "взведено".
///
/// Раньше это делалось через ActionPane/DismissiblePane, но там:
/// - dismissThreshold считается от ПОЛНОЙ ширины экрана (а не от того,
///   насколько раскрыта панель) — из-за этого приходилось дотягивать свайп
///   почти до края, хотя иконка ответа уже была полностью видна;
/// - фон панели ActionPane — обычный прямоугольник того же цвета, что и
///   остальной интерфейс, поэтому визуально сливался с тёмным фоном чата
///   и не давал понять, где именно проходит "точка взвода".
///
/// Здесь вместо этого: сообщение сдвигается пальцем максимум на [_maxDrag],
/// а взводится (готово сработать) уже на [_triggerDrag] — заметно раньше
/// максимума. Круглый бейдж-индикатор проявляется по мере свайпа и меняет
/// цвет + даёт haptic-отклик в момент взвода, так что видно точку, после
/// которой можно просто отпустить палец в любом месте — сообщение вернётся
/// на место, а onReply всё равно сработает.
class SwipeToReplyMessage extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final bool enabled;

  const SwipeToReplyMessage({
    super.key,
    required this.child,
    required this.onReply,
    this.enabled = true,
  });

  @override
  State<SwipeToReplyMessage> createState() => _SwipeToReplyMessageState();
}

class _SwipeToReplyMessageState extends State<SwipeToReplyMessage>
    with SingleTickerProviderStateMixin {
  /// Предел смещения сообщения при свайпе.
  static const double _maxDrag = 74;

  /// Порог "взвода" — заметно меньше [_maxDrag], чтобы не нужно было
  /// дотягивать свайп до предела.
  static const double _triggerDrag = 40;

  /// Сколько пикселей нужно пройти пальцем, прежде чем решать, что это
  /// за жест (влево/вправо/вертикаль) — небольшой "слоп", как у обычных
  /// жестовых распознавателей Flutter.
  static const double _decisionSlop = 8;

  static const double _indicatorSize = 32;

  late final AnimationController _returnController;
  Animation<double>? _returnAnimation;

  double _dragExtent = 0;
  bool _armed = false;

  // Ручное отслеживание жеста через Listener (см. build()) — почему не
  // GestureDetector.onHorizontalDrag*: этот экран открыт через
  // SwipeToDismissRoute, который сам вешает HorizontalDragGestureRecognizer
  // на весь экран для закрытия свайпом вправо. Если здесь тоже завести
  // настоящий распознаватель горизонтального drag, оба будут конкурировать
  // в одной gesture arena за один и тот же палец — и, поскольку этот виджет
  // вложен глубже (ближе к пальцу при hit-test'е), он обычно выигрывает
  // арену первым и перехватывает свайп по экрану, даже если пользователь
  // тянул вправо, а не влево.
  //
  // Listener в арене не участвует вообще — он получает "сырые" события
  // указателя независимо от того, кто выиграл арену выше по дереву, и
  // ничего не отбирает у HorizontalDragGestureRecognizer роута. Поэтому
  // направление жеста (влево/вправо/вертикаль) определяем сами вручную:
  // реагируем только на явно горизontal-влево движение, во всех остальных
  // случаях просто ничего не делаем — событие спокойно долетает до роута.
  double _accumulatedDx = 0;
  double _accumulatedDy = 0;

  /// null — направление ещё не определено (не прошли _decisionSlop);
  /// true — жест наш (тянем сообщение влево);
  /// false — жест не наш (вправо или вертикаль) — просто игнорируем.
  bool? _weOwnGesture;

  @override
  void initState() {
    super.initState();
    _returnController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          setState(() => _dragExtent = _returnAnimation?.value ?? 0);
        });
  }

  @override
  void dispose() {
    _returnController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _returnController.stop();
    _accumulatedDx = 0;
    _accumulatedDy = 0;
    _weOwnGesture = null;
  }

  void _onPointerMove(PointerMoveEvent event) {
    _accumulatedDx += event.delta.dx;
    _accumulatedDy += event.delta.dy;

    if (_weOwnGesture == null) {
      final distance = Offset(_accumulatedDx, _accumulatedDy).distance;
      if (distance < _decisionSlop) return; // ещё рано решать

      // Наш жест — только если движение преимущественно горизонтальное
      // И влево. Вправо или вертикаль — отдаём роуту/скроллу, дальше не
      // трогаем _dragExtent вообще для этого касания.
      final isHorizontalDominant =
          _accumulatedDx.abs() > _accumulatedDy.abs() * 1.2;
      _weOwnGesture = isHorizontalDominant && _accumulatedDx < 0;

      if (!_weOwnGesture!) return;
    }

    if (_weOwnGesture != true) return;

    final next = (_dragExtent + event.delta.dx).clamp(-_maxDrag, 0.0);
    setState(() => _dragExtent = next);

    final isArmedNow = next.abs() >= _triggerDrag;
    if (isArmedNow && !_armed) {
      setState(() => _armed = true);
      HapticFeedback.mediumImpact();
    } else if (!isArmedNow && _armed) {
      setState(() => _armed = false);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _finishGesture();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _finishGesture();
  }

  void _finishGesture() {
    final ownedIt = _weOwnGesture == true;
    _weOwnGesture = null;
    if (!ownedIt) return; // жест был не наш — двигать нечего

    final shouldReply = _armed;
    _armed = false;
    _animateBack();
    if (shouldReply && widget.enabled) {
      widget.onReply();
    }
  }

  void _animateBack() {
    if (_dragExtent == 0) return;
    _returnAnimation = Tween<double>(begin: _dragExtent, end: 0).animate(
      CurvedAnimation(parent: _returnController, curve: Curves.easeOutCubic),
    );
    _returnController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final progress = (_dragExtent.abs() / _triggerDrag).clamp(0.0, 1.0);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          if (_dragExtent != 0)
            Positioned(
              right: 12,
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.6 + 0.4 * progress,
                  child: Container(
                    width: _indicatorSize,
                    height: _indicatorSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Насыщенный акцентный цвет + смена оттенка в момент
                      // взвода — контраст с тёмным фоном чата гарантирован
                      // независимо от того, что нарисовано позади.
                      color: _armed
                          ? AppColors.blurple
                          : AppColors.blurple.withOpacity(0.55),
                      boxShadow: _armed
                          ? [
                              BoxShadow(
                                color: AppColors.blurple.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      CupertinoIcons.arrow_turn_up_left,
                      color: AppColors.onBlurple,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

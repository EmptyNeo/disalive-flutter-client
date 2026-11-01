import 'dart:async';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Переиспользуемый Cupertino Toast для отображения ошибок и уведомлений.
/// Не использует Material-виджеты, полностью соответствует дизайну приложения.
class CustomToast {
  static OverlayEntry? _currentOverlayEntry;
  static GlobalKey<_ToastWidgetState>? _currentToastKey;
  static Timer? _autoDismissTimer;

  /// Показывает toast-уведомление поверх текущего интерфейса.
  static void open({
    required BuildContext context,
    Color? color = AppColors.errorRed,
    IconData? icon = CupertinoIcons.exclamationmark_circle_fill,
    required String message,
  }) {
    // Если уже есть активный toast, скрываем его мгновенно перед показом нового
    _hide(immediate: true);

    final toastKey = GlobalKey<_ToastWidgetState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        key: toastKey,
        icon: icon,
        color: color,
        message: message,
        onDismissed: () => _removeOverlay(entry),
      ),
    );

    _currentToastKey = toastKey;
    _currentOverlayEntry = entry;
    Overlay.of(context).insert(entry);

    // Автоматическое скрытие через 5 секунд
    _autoDismissTimer = Timer(
      const Duration(seconds: 5),
      () => _hide(immediate: false),
    );
  }

  /// Скрывает toast. Если immediate=true, убирает мгновенно (для замены на новый).
  /// Если false, проигрывает анимацию исчезновения.
  static void _hide({bool immediate = false}) {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;

    if (immediate) {
      _removeOverlay();
    } else {
      // 🎯 Запускаем обратную анимацию
      final toastState = _currentToastKey?.currentState;
      if (toastState == null) {
        _removeOverlay();
      } else {
        toastState.hide();
      }
    }
  }

  static void _removeOverlay([OverlayEntry? entry]) {
    final target = entry ?? _currentOverlayEntry;
    if (target == null) return;

    if (identical(_currentOverlayEntry, target)) {
      _autoDismissTimer?.cancel();
      _autoDismissTimer = null;
      _currentOverlayEntry = null;
      _currentToastKey = null;
    }

    if (target.mounted) target.remove();
  }
}

class _ToastWidget extends StatefulWidget {
  final IconData? icon;
  final Color? color;
  final String message;
  final VoidCallback onDismissed;

  const _ToastWidget({
    super.key,
    this.icon = CupertinoIcons.exclamationmark_circle_fill,
    this.color = AppColors.errorRed,
    required this.message,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Запускаем анимацию появления сразу после инициализации
    _controller.forward();
  }

  /// 🎯 Метод, который вызывает статический класс CustomToast для плавного скрытия
  void hide() {
    _controller.reverse().then((_) {
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16.0;

    return Positioned(
      bottom: bottomPadding,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: false,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onTap: () {
                // Пользователь может закрыть toast тапом по нему
                CustomToast._hide(immediate: false);
              },
              // 🎯 РЕШЕНИЕ ПРОБЛЕМЫ ОБРЕЗКИ:
              // Border вынесен на внешний Container, чтобы ClipRRect его не обрезал
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.divider,
                    // Чуть ярче для видимости
                    width: 0.6,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    // Цвет фона перенесен внутрь, чтобы не конфликтовать с border
                    color: AppColors.lightGrey,
                    child: Row(
                      children: [
                        Icon(widget.icon, color: widget.color, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: AppText.mediumTextStyle.copyWith(
                              color: AppColors.white,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => CustomToast._hide(immediate: false),
                          child: Icon(
                            CupertinoIcons.clear,
                            color: AppColors.greyple,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

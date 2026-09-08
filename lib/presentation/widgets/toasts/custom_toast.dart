import 'dart:async';
import 'dart:ui';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Переиспользуемый Cupertino Toast для отображения ошибок и уведомлений.
/// Не использует Material-виджеты, полностью соответствует дизайну приложения.
class CustomToast {
  static OverlayEntry? _currentOverlayEntry;
  static Timer? _autoDismissTimer;

  // 🎯 Ключ для управления анимацией скрытия из статического метода
  static final GlobalKey<_ToastWidgetState> _toastKey =
      GlobalKey<_ToastWidgetState>();

  /// Показывает toast-уведомление поверх текущего интерфейса.
  static void show(BuildContext context, String message) {
    // Если уже есть активный toast, скрываем его мгновенно перед показом нового
    _hide(immediate: true);

    _currentOverlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        key: _toastKey,
        message: message,
        onDismissed: _removeOverlay,
      ),
    );

    Overlay.of(context).insert(_currentOverlayEntry!);

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
      _toastKey.currentState?.hide();
    }
  }

  static void _removeOverlay() {
    if (_currentOverlayEntry != null) {
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null;
    }
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismissed;

  const _ToastWidget({
    super.key,
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
                        const Icon(
                          CupertinoIcons.exclamationmark_circle_fill,
                          color: AppColors.errorRed,
                          size: 24,
                        ),
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

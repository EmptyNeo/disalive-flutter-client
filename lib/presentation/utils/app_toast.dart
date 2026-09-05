// presentation/utils/app_toast.dart
import 'dart:async';

import 'package:flutter/cupertino.dart';

/// Короткий тост снизу экрана — на пару секунд и без явного закрытия.
/// Cupertino не даёт SnackBar из коробки, а гонять CupertinoAlertDialog ради
/// "Скопировано" избыточно.
///
/// Переиспользуемый — не завязан на копирование, годится для любой короткой
/// обратной связи ("Сохранено", "Удалено" и т.п.).
class AppToast {
  const AppToast._();

  static OverlayEntry? _current;

  static void show(BuildContext context, String message) {
    _current?.remove();

    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (context) => _ToastWidget(message: message),
    );
    _current = entry;
    overlay.insert(entry);

    Timer(const Duration(seconds: 2), () {
      entry.remove();
      if (identical(_current, entry)) _current = null;
    });
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({required this.message});

  final String message;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: MediaQuery.of(context).padding.bottom + 24,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _controller,
          child: Align(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.darkBackgroundGray.withValues(
                  alpha: 0.92,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

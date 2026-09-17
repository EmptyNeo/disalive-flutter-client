import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class PrivacySwitch extends StatelessWidget {
  final bool value;
  final bool isLoading;
  final bool isEnabled; // 🎯 ДОБАВЛЕНО
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? trackColor;

  const PrivacySwitch({
    super.key,
    required this.value,
    required this.isLoading,
    required this.onChanged,
    this.isEnabled = true, // 🎯 ДОБАВЛЕНО
    this.activeColor,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedActiveColor = activeColor ?? AppColors.blurple;
    final resolvedTrackColor = trackColor ?? AppColors.divider;
    const pureWhite = Color(0xFFFFFFFF);

    return GestureDetector(
      // 🎯 ИСПРАВЛЕНО: Блокируем нажатие, если isLoading ИЛИ !isEnabled
      onTap: (!isEnabled || isLoading) ? null : () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31),
          color: value ? resolvedActiveColor : resolvedTrackColor,
        ),
        child: Stack(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          children: [
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: isLoading
                  ? const SizedBox(
                      width: 27,
                      height: 27,
                      child: CupertinoActivityIndicator(
                        radius: 9,
                        color: pureWhite,
                      ),
                    )
                  : Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: pureWhite,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withValues(
                              alpha: 0.15,
                            ),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

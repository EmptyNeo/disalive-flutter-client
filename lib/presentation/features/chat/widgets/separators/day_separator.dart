import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Разделитель дня между группами сообщений ("Сегодня" / "Вчера" / "ДД.ММ" /
/// "ДД.ММ.ГГ") — лейбл строго из [UtilDate.formatDayTime] с dayLabel: true,
/// чтобы текст совпадал с тем, как чат подписывает дни в остальном UI.
class DaySeparator extends StatelessWidget {
  final String label;

  const DaySeparator({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.darkGrey.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: AppText.lowTextStyle.copyWith(
              color: AppColors.greyple,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

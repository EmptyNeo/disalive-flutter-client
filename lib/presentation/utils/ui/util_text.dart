import 'package:disalive/presentation/utils/ui/util_date.dart';

class UtilText {
  UtilText._();

  static String formatLastVisit(String? lastVisit, bool followLastVisit) {
    // Если lastVisit нет или пользователь скрыл время посещения
    if (lastVisit == null || lastVisit.isEmpty || !followLastVisit) {
      return 'Был(а) недавно'; // Или 'Был недавно', если хочешь строго как в JS
    }

    final date = UtilDate.parseDateTime(lastVisit);
    if (date == null) return 'Был(а) недавно';

    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday) {
      final timeStr = '${UtilDate.two(date.hour)}:${UtilDate.two(date.minute)}';
      return 'Был(а) в $timeStr';
    } else {
      // Для других дней используем формат ДД.ММ или ДД.ММ.ГГ
      final dateStr = (date.year == now.year)
          ? '${UtilDate.two(date.day)}.${UtilDate.two(date.month)}'
          : '${UtilDate.two(date.day)}.${UtilDate.two(date.month)}.${date.year % 100}';
      return 'Был(а) $dateStr';
    }
  }

}

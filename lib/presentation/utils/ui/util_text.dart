import 'package:disalive/presentation/utils/ui/util_date.dart';
import 'package:intl/intl.dart';

class UtilText {
  UtilText._();

  static String formatLastVisit(String? lastVisit, bool followLastVisit) {
    // Если lastVisit нет или пользователь скрыл время посещения
    if (lastVisit == null || lastVisit.isEmpty || !followLastVisit) {
      return 'Был(а) недавно';
    }

    try {
      // 1. Парсим строку как UTC время
      final utcDate = DateTime.parse(lastVisit).toUtc();

      // 2. Конвертируем в локальное время устройства пользователя 🎯
      final localDate = utcDate.toLocal();
      final now = DateTime.now();

      final difference = now.difference(localDate);

      if (difference.inMinutes < 1) {
        return 'был(а) только что';
      } else if (difference.inMinutes < 60) {
        return 'был(а) ${difference.inMinutes} мин. назад';
      } else if (difference.inHours < 24) {
        return 'был(а) ${difference.inHours} ч. назад';
      } else if (difference.inDays < 7) {
        return 'был(а) ${difference.inDays} дн. назад';
      } else {
        final formatter = DateFormat('d MMMM yyyy, HH:mm', 'ru_RU');
        return 'был(а) ${formatter.format(localDate)}';
      }
    } catch (e) {
      return 'был(а) недавно';
    }
  }
}

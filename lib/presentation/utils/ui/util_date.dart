/// Утилиты форматирования дат/времени для UI (списки чатов и т.п.).
class UtilDate {
  UtilDate._();

  static String formatTime(String? createdAt) {
    if (createdAt == null) return '';

    final normalized = createdAt.contains('T')
        ? createdAt
        : createdAt.replaceFirst(' ', 'T');

    final utcTime = DateTime.tryParse('${normalized}Z');
    if (utcTime == null) return '';

    final local = utcTime.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Парсит бэкендовую строку времени ("2026-08-20 21:24:36" и т.п.) в
  /// [DateTime] (локальное время). Возвращает null, если строка пустая или
  /// не парсится. Вынесено отдельно, чтобы форматирование для UI и
  /// сортировка по времени последнего сообщения использовали один и тот же
  /// парсинг и не расходились в трактовке формата.
  static DateTime? parseDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
    final date = DateTime.tryParse(normalized);
    return date?.toLocal();
  }

  static String? formatDayTime(String? raw, bool dayLabel) {
    if (raw == null || raw.isEmpty) return null;

    final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
    final date = DateTime.tryParse(normalized);

    if (date == null) return raw;

    final local = date.toLocal();

    final now = DateTime.now();

    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (isToday) {
      if (dayLabel) {
        return 'Сегодня';
      }
      return '${two(local.hour)}:${two(local.minute)}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;
    if (isYesterday) return 'Вчера';

    if (local.year == now.year) {
      return '${two(local.day)}.${two(local.month)}';
    }
    return '${two(local.day)}.${two(local.month)}.${local.year % 100}';
  }

  static String two(int value) => value.toString().padLeft(2, '0');

}

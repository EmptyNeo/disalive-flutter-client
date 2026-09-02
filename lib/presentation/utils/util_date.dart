/// Утилиты форматирования дат/времени для UI (списки чатов и т.п.).
class UtilDate {
  UtilDate._();

  static String formatTime(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final local = dt.toLocal();
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

  /// Парсит бэкендовую строку времени ("2026-08-20 21:24:36" и т.п.) и
  /// возвращает короткое читаемое представление: "21:24" сегодня, "Вчера",
  /// "20.08" в этом году, иначе "20.08.25". При невозможности распарсить
  /// возвращает исходную строку, чтобы не потерять данные молча.
  static String? formatChatTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final local = parseDateTime(raw);
    if (local == null) return raw;

    final now = DateTime.now();

    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (isToday) {
      return '${_two(local.hour)}:${_two(local.minute)}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;
    if (isYesterday) return 'Вчера';

    if (local.year == now.year) {
      return '${_two(local.day)}.${_two(local.month)}';
    }
    return '${_two(local.day)}.${_two(local.month)}.${local.year % 100}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

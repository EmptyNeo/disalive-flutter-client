// lib/presentation/utils/pluralize.dart
class Pluralize {
  Pluralize._();

  /// Склоняет числительные по падежам
  /// [number] — число
  /// [one] — "вложение"
  /// [two] — "вложения"
  /// [five] — "вложений"
  static String format(int number, String one, String two, String five) {
    final absNumber = number.abs();

    if (absNumber % 100 >= 11 && absNumber % 100 <= 19) {
      return five;
    }

    switch (absNumber % 10) {
      case 1:
        return one;
      case 2:
      case 3:
      case 4:
        return two;
      default:
        return five;
    }
  }

  /// Удобный метод для участников
  static String members(int count) {
    return '$count ${format(count, 'участник', 'участника', 'участников')}';
  }

  /// Удобный метод для вложений
  static String attachments(int count) {
    return '$count ${format(count, 'вложение', 'вложения', 'вложений')}';
  }

  /// Удобный метод для файлов
  static String files(int count) {
    return '$count ${format(count, 'файл', 'файла', 'файлов')}';
  }

  /// Удобный метод для фотографий
  static String photos(int count) {
    return '$count ${format(count, 'фотография', 'фотографии', 'фотографий')}';
  }
}
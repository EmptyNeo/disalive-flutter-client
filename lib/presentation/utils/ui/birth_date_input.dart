import 'package:flutter/services.dart';

class BirthDateInputFormatter extends TextInputFormatter {
  const BirthDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    var digitsBeforeCursor = newValue.text
        .substring(
          0,
          newValue.selection.baseOffset.clamp(0, newValue.text.length),
        )
        .replaceAll(RegExp(r'\D'), '')
        .length;
    if (newValue.text.length < oldValue.text.length &&
        digits.isNotEmpty &&
        digits == oldValue.text.replaceAll(RegExp(r'\D'), '')) {
      final index = (digitsBeforeCursor - 1).clamp(0, digits.length - 1);
      digits = digits.replaceRange(index, index + 1, '');
      digitsBeforeCursor = index;
    }
    if (digits.length > 8) {
      digits = digits.substring(0, 8);
    }
    digitsBeforeCursor = digitsBeforeCursor.clamp(0, digits.length);
    final buffer = StringBuffer();
    var cursor = 0;
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('.');
      if (i == digitsBeforeCursor) cursor = buffer.length;
      buffer.write(digits[i]);
    }
    if (digitsBeforeCursor == digits.length) cursor = buffer.length;
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

class BirthDateInput {
  static String display(String? value) {
    if (value == null || value.isEmpty) return '';
    final parts = value.split('-');
    if (parts.length != 3) return value;
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  static String? normalize(String value) {
    if (value.trim().isEmpty) return null;
    final match = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(value);
    if (match == null) {
      throw const FormatException('Укажите дату в формате ДД.ММ.ГГГГ');
    }
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    final date = DateTime.utc(year, month, day);
    final today = DateTime.now().toUtc();
    if (year < 1 ||
        date.year != year ||
        date.month != month ||
        date.day != day ||
        date.isAfter(DateTime.utc(today.year, today.month, today.day))) {
      throw const FormatException('Некорректная дата рождения');
    }
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }
}

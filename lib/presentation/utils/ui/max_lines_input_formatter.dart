import 'package:flutter/services.dart'; // Не забудь этот импорт!

class MaxLinesInputFormatter extends TextInputFormatter {
  final int maxLines;

  MaxLinesInputFormatter(this.maxLines);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final lineCount = newValue.text.split('\n').length;

    if (lineCount > maxLines) {
      return oldValue;
    }

    return newValue;
  }
}
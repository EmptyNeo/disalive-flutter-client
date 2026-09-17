import 'package:flutter/cupertino.dart';

extension ColorHexExtension on Color {
  String toHex() {
    // Берём последние 6 hex-символов (RRGGBB), отбрасывая альфа-канал
    final hex = toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    final rgb = hex.substring(2); // Убираем первые 2 символа (AA)
    return '#$rgb';
  }
}

import 'dart:ui';

import 'package:disalive/app/theme/app_theme.dart';

class ColorService {
  static Color parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return AppColors.blurple;
    final hex = hexColor.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

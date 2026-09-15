// lib/presentation/bloc/theme/theme_state.dart
import 'package:disalive/domain/enums/app_theme_mode.dart';
import 'package:flutter/cupertino.dart';

class ThemeState {
  final CupertinoThemeData themeData;
  final AppThemeMode themeMode;

  ThemeState({required this.themeData, required this.themeMode});
}
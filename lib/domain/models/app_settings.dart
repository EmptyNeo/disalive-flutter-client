// lib/domain/models/app_settings.dart

import 'package:disalive/domain/enums/app_theme_mode.dart';

class AppSettings {
  final bool isVoiceHintShown;
  final AppThemeMode themeMode;

  const AppSettings({
    this.isVoiceHintShown = false,
    this.themeMode = AppThemeMode.dark,
  });

  AppSettings copyWith({bool? isVoiceHintShown, AppThemeMode? themeMode}) {
    return AppSettings(
      isVoiceHintShown: isVoiceHintShown ?? this.isVoiceHintShown,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

// lib/domain/models/app_settings.dart

class AppSettings {
  final bool isVoiceHintShown;
  final String themeMode;

  const AppSettings({
    this.isVoiceHintShown = false,
    this.themeMode = 'dark',
  });

  AppSettings copyWith({
    bool? isVoiceHintShown,
    String? themeMode,
  }) {
    return AppSettings(
      isVoiceHintShown: isVoiceHintShown ?? this.isVoiceHintShown,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
enum AppThemeMode {
  system('system', 'Системная'),
  light('light', 'Светлая'),
  dark('dark', 'Тёмная'),
  amoled('amoled', 'AMOLED (Чёрная)'); // Готова к расширению

  final String value;
  final String displayName;

  const AppThemeMode(this.value, this.displayName);

  static AppThemeMode fromString(String value) {
    return AppThemeMode.values.firstWhere(
          (e) => e.value == value,
      orElse: () => AppThemeMode.system,
    );
  }
}
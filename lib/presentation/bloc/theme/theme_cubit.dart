// lib/presentation/bloc/theme/theme_cubit.dart
import 'package:disalive/presentation/bloc/theme/theme_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/app_settings.dart';
import 'package:disalive/domain/repositories/setting_repository.dart';
import 'package:disalive/domain/enums/app_theme_mode.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final SettingsRepository _settingsRepository;

  ThemeCubit(this._settingsRepository)
    : super(
        ThemeState(
          themeData: AppTheme.darkTheme,
          themeMode: AppThemeMode.system,
        ),
      );

  Future<void> loadTheme() async {
    final result = await _settingsRepository.getSettings();

    result.fold(
      (failure) {
        // Fallback на системную тему при ошибке
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final isDark = brightness == Brightness.dark;
        _applyTheme(AppThemeMode.system, isDark);
      },
      (settings) {
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final isSystemDark = brightness == Brightness.dark;

        // Если выбрана системная тема, используем реальную яркость системы
        final isDark = settings.themeMode == AppThemeMode.system
            ? isSystemDark
            : (settings.themeMode == AppThemeMode.dark ||
                  settings.themeMode == AppThemeMode.amoled);

        _applyTheme(settings.themeMode, isDark);
      },
    );
  }

  Future<void> setTheme(AppThemeMode newMode) async {
    final settingsResult = await _settingsRepository.getSettings();
    settingsResult.fold((failure) => null, (settings) async {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final isSystemDark = brightness == Brightness.dark;

      final isDark = newMode == AppThemeMode.system
          ? isSystemDark
          : (newMode == AppThemeMode.dark || newMode == AppThemeMode.amoled);

      _applyTheme(newMode, isDark);

      final result = await _settingsRepository.saveSettings(
        AppSettings(
          themeMode: newMode,
          isVoiceHintShown: settings.isVoiceHintShown,
        ),
      );

      result.fold(
        (failure) => null,
        (_) => emit(ThemeState(themeData: state.themeData, themeMode: newMode)),
      );
    });
  }

  // 🎯 Вспомогательный метод для применения темы
  void _applyTheme(AppThemeMode mode, bool isDark) {
    AppColors.setThemeMode(isDark, isAmoled: mode == AppThemeMode.amoled);

    CupertinoThemeData theme;
    switch (mode) {
      case AppThemeMode.light:
        theme = AppTheme.lightTheme;
        break;
      case AppThemeMode.amoled:
        theme = AppTheme.amoledTheme;
        break;
      case AppThemeMode.dark:
      case AppThemeMode.system:
        theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        break;
    }

    emit(ThemeState(themeData: theme, themeMode: mode));
  }
}

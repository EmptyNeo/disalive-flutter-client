// presentation/bloc/theme/theme_cubit.dart
import 'package:disalive/presentation/bloc/theme/theme_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/app_settings.dart';
import 'package:disalive/domain/repositories/setting_repository.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final SettingsRepository _settingsRepository;

  ThemeCubit(this._settingsRepository)
      : super(ThemeState(themeData: AppTheme.darkTheme, themeMode: 'dark'));

  Future<void> loadTheme() async {
    final result = await _settingsRepository.getSettings();
    result.fold(
          (failure) {
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final systemMode = brightness == Brightness.dark ? 'dark' : 'light';
        final isDark = systemMode == 'dark';
        AppColors.setThemeMode(isDark);
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        emit(ThemeState(themeData: theme, themeMode: systemMode));
      },
          (settings) {
        final isDark = settings.themeMode == 'dark';
        AppColors.setThemeMode(isDark);
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        emit(ThemeState(themeData: theme, themeMode: settings.themeMode));
      },
    );
  }

  Future<void> toggleTheme() async {
    final newMode = state.themeMode == 'dark' ? 'light' : 'dark';
    final isDark = newMode == 'dark';

    AppColors.setThemeMode(isDark);

    final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;

    final result = await _settingsRepository.saveSettings(
      AppSettings(
        themeMode: newMode,
        isVoiceHintShown: state.themeMode == 'dark' ? false : true,
      ),
    );

    result.fold(
          (failure) => null,
          (_) => emit(ThemeState(themeData: theme, themeMode: newMode)),
    );
  }
}
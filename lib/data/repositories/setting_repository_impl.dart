import 'package:dartz/dartz.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/app_theme_mode.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/app_settings.dart';
import 'package:disalive/domain/repositories/setting_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _preferences;
  static const String _keyVoiceHintShown = 'voice_hint_shown';
  static const String _keyThemeMode = 'theme_mode';

  SettingsRepositoryImpl(this._preferences);

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    try {
      final isShown = _preferences.getBool(_keyVoiceHintShown) ?? false;
      final themeMode = AppThemeMode.fromString(
        _preferences.getString(_keyThemeMode) ?? AppThemeMode.dark.value,
      );
      return Right(
        AppSettings(isVoiceHintShown: isShown, themeMode: themeMode),
      );
    } catch (e) {
      return Left(CacheFailure('Failed to load settings: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(AppSettings settings) async {
    try {
      await _preferences.setBool(_keyVoiceHintShown, settings.isVoiceHintShown);
      await _preferences.setString(_keyThemeMode, settings.themeMode.value);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save settings: $e'));
    }
  }
}

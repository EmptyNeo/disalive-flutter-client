import 'package:flutter/cupertino.dart';

class AppColors {
  // Базовые цвета (не меняются от темы)
  static const Color blurple = Color(0xFF0E6EE2);
  static const Color green = Color(0xFF43B581);
  static const Color red = Color(0xFFED3F49);
  static const Color linkBlue = Color(0xFF00AFF4);
  static const Color errorRed = Color(0xFFED4245);
  static const Color yellow = Color(0xFFFAA81A);
  static const Color successGreen = CupertinoColors.systemGreen;

  // Текущий режим темы (по умолчанию темная)
  static bool _isDarkMode = true;
  static bool _isAmoled = false;

  // Цвета для темной темы
  static const Color _darkDark = Color(0xFF141318);
  static const Color _darkMainBackground = Color(0xFF1C1D22);
  static const Color _darkMainGrey = Color(0xFF373A43);
  static const Color _darkActionGrey = Color(0xFF26262E);
  static const Color _darkLightGrey = Color(0xFF27272F);
  static const Color _darkDarkGrey = Color(0xFF2D2D35);
  static const Color _darkDivider = Color(0xFF40444B);
  static const Color _darkIconGrey = Color(0xFFC6C7CC);
  static const Color _darkGreyple = Color(0xFF82858E);

  static const Color _amoledBackground = Color(0xFF000000);
  static const Color _amoledMainGrey = Color(0xFF0A0A0C);
  static const Color _amoledActionGrey = Color(0xFF151518);
  static const Color _amoledLightGrey = Color(0xFF101013);
  static const Color _amoledDarkGrey = Color(0xFF1C1C20);
  static const Color _amoledDivider = Color(0xFF2B2B30);

  static const Color _darkHighlight = Color(0x330E6EE2);
  static const Color darkHighlight = _darkHighlight;

  // Цвета для светлой темы
  static const Color _lightDark = Color(0xFFE3E5E8); // Сайдбар серверов (Light)
  static const Color _lightMainBackground = Color(
    0xFFFFFFFF,
  ); // Фон чата (Light)
  static const Color _lightMainGrey = Color(
    0xFFF2F3F5,
  ); // Сайдбар каналов (Light)
  static const Color _lightActionGrey = Color(
    0xFFEBEDEF,
  ); // Поле ввода/кнопки (Light)
  static const Color _lightDivider = Color(0xFFE3E5E8);
  static const Color _lightGreyple = Color(
    0xFF5C6370,
  ); // Вспомогательный текст (Light)
  static const Color _lightIconGrey = Color(
    0xFF4E5058,
  ); // Иконки в светлой теме

  static const Color _lightDarkGrey = Color(0xFFE0E0E0);
  static const Color _lightLightGrey = Color(0xFFFAFAFA);

  static const Color _lightHighlight = Color(0x400E6EE2);

  static const Color gold = Color(0xFFFAA61A); // Discord-стиль золотой

  // Динамические цвета (возвращают значение в зависимости от темы)
  static Color get dark =>
      _isAmoled ? _amoledBackground : (_isDarkMode ? _darkDark : _lightDark);

  static Color get highlight => _isDarkMode ? _darkHighlight : _lightHighlight;

  static Color get onBlurple => CupertinoColors.white;

  static Color get mainBackground => _isAmoled
      ? _amoledBackground
      : (_isDarkMode ? _darkMainBackground : _lightMainBackground);

  static Color get mainGrey => _isAmoled
      ? _amoledMainGrey
      : (_isDarkMode ? _darkMainGrey : _lightMainGrey);

  static Color get actionGrey => _isAmoled
      ? _amoledActionGrey
      : (_isDarkMode ? _darkActionGrey : _lightActionGrey);

  static Color get lightGrey => _isAmoled
      ? _amoledLightGrey
      : (_isDarkMode ? _darkLightGrey : _lightLightGrey);

  static Color get darkGrey => _isAmoled
      ? _amoledDarkGrey
      : (_isDarkMode ? _darkDarkGrey : _lightDarkGrey);

  static Color get divider =>
      _isAmoled ? _amoledDivider : (_isDarkMode ? _darkDivider : _lightDivider);

  static Color get iconGrey => _isDarkMode ? _darkIconGrey : _lightIconGrey;

  static Color get greyple => _isDarkMode ? _darkGreyple : _lightGreyple;

  static Color get white =>
      _isDarkMode ? CupertinoColors.white : Color(0xFF060607);

  // Material Colors.grey == 0xFF9E9E9E, Colors.grey[600] == 0xFF757575 —
  // сохраняю те же значения через прямой Color, чтобы визуально ничего
  // не поменялось при уходе от material.
  static Color get grey => _isDarkMode ? Color(0xFF9E9E9E) : Color(0xFF757575);

  // Метод для обновления темы
  static void setThemeMode(bool isDarkMode, {bool isAmoled = false}) {
    _isDarkMode = isDarkMode;
    _isAmoled = isDarkMode && isAmoled;
  }

  // Метод для получения текущего режима
  static bool isDarkMode() => _isDarkMode;

  // Остальные цвета остаются статическими.
  // Material-палитра grey[400]/[600]/[700]/[800] — те же hex-значения,
  // просто без зависимости от Colors.
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color transparent = CupertinoColors.transparent;

  // 🎯 Адаптивные цвета для стеклянных панелей (Glassmorphism)
  // В светлой теме используем чистый белый и очень светлый серый для имитации нативного iOS-блюра
  static Color get glassPanelTop => _isAmoled
      ? _amoledActionGrey
      : (_isDarkMode ? const Color(0xFF2F3135) : const Color(0xFFFFFFFF));

  static Color get glassPanelBottom => _isAmoled
      ? _amoledMainGrey
      : (_isDarkMode ? const Color(0xFF2C2F33) : const Color(0xFFF2F3F5));

  static Color get glassPanelPressed => _isAmoled
      ? _amoledDarkGrey
      : (_isDarkMode ? const Color(0xFF404348) : const Color(0xFFE3E5E8));
}

class AppText {
  static TextStyle lowTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static TextStyle mediumTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static TextStyle highTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}

class AppTheme {
  static final CupertinoThemeData darkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.blurple,
    primaryContrastingColor: AppColors.onBlurple,
    scaffoldBackgroundColor: AppColors._darkMainBackground,
    barBackgroundColor: AppColors._darkMainBackground,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.blurple,
      textStyle: AppText.mediumTextStyle.copyWith(color: AppColors.white),
      navTitleTextStyle: AppText.highTextStyle.copyWith(color: AppColors.white),
      navLargeTitleTextStyle: AppText.highTextStyle.copyWith(
        color: AppColors.white,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      navActionTextStyle: AppText.mediumTextStyle.copyWith(
        color: AppColors.linkBlue,
      ),
      tabLabelTextStyle: AppText.lowTextStyle.copyWith(
        color: AppColors.iconGrey,
      ),
      actionTextStyle: AppText.mediumTextStyle.copyWith(
        color: AppColors.linkBlue,
      ),
      pickerTextStyle: AppText.mediumTextStyle.copyWith(color: AppColors.white),
      dateTimePickerTextStyle: AppText.mediumTextStyle.copyWith(
        color: AppColors.white,
      ),
    ),
  );

  static final CupertinoThemeData amoledTheme = darkTheme.copyWith(
    scaffoldBackgroundColor: AppColors._amoledBackground,
    barBackgroundColor: AppColors._amoledBackground,
  );

  static final CupertinoThemeData lightTheme = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.blurple,
    primaryContrastingColor: AppColors.onBlurple,
    scaffoldBackgroundColor: CupertinoColors.white,
    barBackgroundColor: CupertinoColors.white,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.blurple,
      // Material Colors.black87 == 0xDD000000 (87% opacity black) — same
      // value, no material dependency.
      textStyle: AppText.mediumTextStyle.copyWith(color: Color(0xDD000000)),
      navTitleTextStyle: AppText.highTextStyle.copyWith(
        color: Color(0xDD000000),
      ),
      navLargeTitleTextStyle: AppText.highTextStyle.copyWith(
        color: Color(0xDD000000),
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      navActionTextStyle: AppText.mediumTextStyle.copyWith(
        color: AppColors.linkBlue,
      ),
      tabLabelTextStyle: AppText.lowTextStyle.copyWith(
        color: AppColors.grey600,
      ),
      actionTextStyle: AppText.mediumTextStyle.copyWith(
        color: AppColors.linkBlue,
      ),
      pickerTextStyle: AppText.mediumTextStyle.copyWith(
        color: Color(0xDD000000),
      ),
      dateTimePickerTextStyle: AppText.mediumTextStyle.copyWith(
        color: Color(0xDD000000),
      ),
    ),
  );
}

/// Готовые декорации под CupertinoTextField/CupertinoButton/разделители,
/// так как в Cupertino под них нет глобальной темы.
class AppWidgetStyles {
  static BoxDecoration textFieldDecoration({bool focused = false}) =>
      BoxDecoration(
        color: AppColors.actionGrey,
        borderRadius: BorderRadius.circular(5),
        border: focused ? Border.all(color: AppColors.blurple, width: 1) : null,
      );

  // CupertinoButton не принимает ButtonStyle — используйте:
  // CupertinoButton.filled(
  //   color: AppColors.blurple,
  //   padding: AppWidgetStyles.primaryButtonPadding,
  //   borderRadius: BorderRadius.circular(5),
  //   child: ...,
  // )
  static const EdgeInsets primaryButtonPadding = EdgeInsets.symmetric(
    vertical: 15,
  );

  static BoxDecoration get dividerDecoration => BoxDecoration(
    border: Border(top: BorderSide(color: AppColors.divider)),
  );
}

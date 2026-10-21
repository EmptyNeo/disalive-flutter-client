import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppColors.setThemeMode(true));

  test('AMOLED has black canvas and distinct dark surfaces', () {
    AppColors.setThemeMode(true);
    final ordinaryBackground = AppColors.mainBackground;
    final ordinarySurface = AppColors.actionGrey;

    AppColors.setThemeMode(true, isAmoled: true);
    expect(AppTheme.amoledTheme.scaffoldBackgroundColor, CupertinoColors.black);
    expect(AppColors.mainBackground, CupertinoColors.black);
    expect(AppColors.actionGrey, isNot(ordinarySurface));
    expect(AppColors.mainGrey, isNot(CupertinoColors.black));

    AppColors.setThemeMode(true);
    expect(AppColors.mainBackground, ordinaryBackground);
    expect(AppColors.actionGrey, ordinarySurface);
    expect(AppTheme.darkTheme.scaffoldBackgroundColor, ordinaryBackground);
  });
}

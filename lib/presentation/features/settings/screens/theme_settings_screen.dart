import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/app_theme_mode.dart';
import 'package:disalive/presentation/bloc/theme/theme_cubit.dart';
import 'package:disalive/presentation/bloc/theme/theme_state.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return SwipeToDismissRoute.push(
      context,
      (context) => const ThemeSettingsScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return CupertinoPageScaffold(
          backgroundColor: CupertinoColors.transparent,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: AppColors.mainBackground,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      // Хэдер
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 4,
                        ),
                        child: Row(
                          children: [
                            GlassIconButton(
                              icon: CupertinoIcons.back,
                              onTap: () => Navigator.of(context).pop(),
                              size: 36,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Тема оформления',
                              style: AppText.highTextStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: AppColors.white.withValues(alpha: 0.10),
                      ),

                      // Список тем
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          children: AppThemeMode.values.map((mode) {
                            final isSelected = state.themeMode == mode;
                            return _ThemeTile(
                              mode: mode,
                              isSelected: isSelected,
                              onTap: () {
                                context.read<ThemeCubit>().setTheme(mode);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final AppThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 🎯 1. Определяем, какую тему мы ПРЕДВАРИТЕЛЬНО просматриваем
    final isAmoled = mode == AppThemeMode.amoled;
    final isDarkPreview = mode == AppThemeMode.dark || isAmoled;

    // 🎯 2. ЖЕСТКО задаем цвета превью, чтобы они не зависели от текущей темы приложения
    final previewBackgroundColor = isAmoled
        ? const Color(0xFF000000) // Чистый черный для AMOLED
        : (isDarkPreview
              ? const Color(0xFF1C1D22)
              : const Color(0xFFFFFFFF)); // Темный или Белый

    final previewBubbleColor = AppColors.blurple; // Одинаковый для обеих тем

    final previewSecondaryBubbleColor = isDarkPreview
        ? const Color(0xFF2C2F33) // Темно-серый (как glassPanelBottom)
        : const Color(0xFFEBEDEF); // Светло-серый (как actionGrey)

    final previewTextColor = isDarkPreview
        ? CupertinoColors.white
        : const Color(0xFF060607); // Почти черный для светлой темы


    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blurple.withValues(alpha: 0.15)
              : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider,
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 Превью интерфейса
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: previewBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.divider, // 🎯 Адаптивная рамка превью
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Фоновый градиент для AMOLED
                    if (isAmoled)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              CupertinoColors.black,
                              CupertinoColors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),

                    // Пузырь сообщения (справа)
                    Positioned(
                      right: 8,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: previewBubbleColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: CupertinoColors.white.withValues(
                                  alpha: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 30,
                              height: 4,
                              decoration: BoxDecoration(
                                color: CupertinoColors.white.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Пузырь сообщения (слева)
                    Positioned(
                      left: 8,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: previewSecondaryBubbleColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 50,
                              height: 4,
                              decoration: BoxDecoration(
                                color: previewTextColor.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 35,
                              height: 4,
                              decoration: BoxDecoration(
                                color: previewTextColor.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🎯 Название темы и чекбокс
            Row(
              children: [
                Expanded(
                  child: Text(
                    mode.displayName,
                    style: AppText.mediumTextStyle.copyWith(
                      // Здесь используем динамический AppColors.white, так как это текст САМОГО меню настроек
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.blurple : AppColors.greyple,
                      width: 2,
                    ),
                    color: isSelected
                        ? AppColors.blurple
                        : CupertinoColors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          CupertinoIcons.checkmark_alt,
                          color: CupertinoColors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

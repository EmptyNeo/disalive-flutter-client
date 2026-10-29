import 'dart:ui';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/utils/ui/emoji_text_parser.dart';
import 'package:disalive/presentation/widgets/buttons/glass_button.dart';
import 'package:flutter/cupertino.dart';

/// Показывает стеклянное модальное окно подтверждения действия.
/// Возвращает `true`, если пользователь нажал "Подтвердить", и `false` (или null), если "Отмена".
Future<bool?> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String description,
  String confirmText = 'Подтвердить',
  String? cancelText = 'Отмена',
  bool isDestructive = false, // Если true, кнопка подтверждения будет красной
  IconData? icon,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    // Закрытие по тапу вне окна
    barrierLabel: 'ConfirmationModal',
    // Затемняем фон за модалкой для акцента
    barrierColor: CupertinoColors.black.withOpacity(0.4),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: _ConfirmationModalContent(
            title: title,
            description: description,
            confirmText: confirmText,
            cancelText: cancelText,
            isDestructive: isDestructive,
            icon: icon,
          ),
        ),
      );
    },
  );
}

class _ConfirmationModalContent extends StatelessWidget {
  final String title;
  final String description;
  final String confirmText;
  final String? cancelText;
  final bool isDestructive;
  final IconData? icon;

  const _ConfirmationModalContent({
    required this.title,
    required this.description,
    required this.confirmText,
    required this.cancelText,
    required this.isDestructive,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final confirmColor = isDestructive ? AppColors.errorRed : AppColors.blurple;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                // Полупрозрачный темный фон для стекла
                color: AppColors.darkGrey.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: confirmColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 16, color: confirmColor),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppText.highTextStyle.copyWith(
                      color: AppColors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: EmojiTextParser.parse(
                        description,
                        emojiSize: 16,
                        animateEmoji: false,
                      ),
                    ),
                    textAlign: TextAlign.center,
                    style: AppText.mediumTextStyle.copyWith(
                      color: AppColors.greyple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (cancelText != null) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.darkGrey,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.divider,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                cancelText!,
                                textAlign: TextAlign.center,
                                style: AppText.mediumTextStyle.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Кнопка подтверждения
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: confirmColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              confirmText,
                              textAlign: TextAlign.center,
                              style: AppText.mediumTextStyle.copyWith(
                                color: AppColors.onBlurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

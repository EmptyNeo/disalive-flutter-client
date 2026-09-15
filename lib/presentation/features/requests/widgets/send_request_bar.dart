// lib/presentation/features/requests/widgets/send_request_bar.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/widgets/buttons/glass_button.dart';
import 'package:flutter/cupertino.dart';

/// Панель отправки заявки по username.
class SendRequestBar extends StatelessWidget {
  const SendRequestBar({
    super.key,
    required this.controller,
    required this.hasText,
    required this.onSend,
  });

  final TextEditingController controller;
  final ValueNotifier<bool> hasText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      // 🎯 Убрали лишний ClipRRect, так как Container сам отлично обрабатывает borderRadius
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          // 🎯 Динамический фон: тёмно-серый в Dark, светло-серый в Light
          color: AppColors.actionGrey,
          borderRadius: BorderRadius.circular(20),
          // 🎯 Динамическая обводка: видна и контрастна в любой теме
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: controller,
                placeholder: 'Имя пользователя',
                placeholderStyle: AppText.mediumTextStyle.copyWith(
                  color: AppColors.greyple,
                ),
                style: AppText.mediumTextStyle.copyWith(
                  // 🎯 AppColors.white уже динамический (белый в Dark, почти чёрный в Light)
                  color: AppColors.white,
                ),
                cursorColor: AppColors.blurple,
                // Убираем стандартную декорацию Cupertino, чтобы не было двойных рамок
                decoration: const BoxDecoration(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 6),
            ValueListenableBuilder<bool>(
              valueListenable: hasText,
              builder: (context, enabled, _) => GlassButton(
                borderRadius: 32,
                padding: const EdgeInsets.all(8),
                accent: enabled,
                onTap: enabled ? onSend : () {},
                child: Icon(
                  CupertinoIcons.paperplane_fill,
                  size: 14, // Чуть увеличил для лучшей читаемости
                  color: enabled ? AppColors.onBlurple : AppColors.greyple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
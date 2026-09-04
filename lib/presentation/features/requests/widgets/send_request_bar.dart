// lib/presentation/features/requests/widgets/send_request_bar.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/widgets/buttons/glass_button.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:disalive/presentation/widgets/custom_divider.dart';
import 'package:flutter/cupertino.dart';

/// Панель отправки заявки по username — обычная строка над списком (не
/// floating), поэтому без блюра и без измерения высоты.
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.glassPanelBottom.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.1),
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
                    color: AppColors.white,
                  ),
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
                  padding: const EdgeInsets.all(6),
                  accent: enabled,
                  onTap: enabled ? onSend : () {},
                  child: Icon(
                    CupertinoIcons.paperplane_fill,
                    size: 18,
                    color: enabled ? AppColors.white : AppColors.greyple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

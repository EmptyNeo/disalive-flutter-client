import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Универсальный баннер над полем ввода (редактирование, ответ на сообщение и т.д.).
/// Имеет стеклянный стиль с закруглёнными верхними углами.
class InputBannerTop extends StatelessWidget {
  InputBannerTop({
    super.key,
    required this.title,
    required this.icon,
    required this.onClose,
  });

  final String title;
  final IconData icon;
  final Color iconBackgroundColor = AppColors.blurple;
  final Color iconColor = AppColors.onBlurple;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 8),

            // Текст (заголовок + опциональный подзаголовок)
            Expanded(
              child: Text(
                title,
                style: AppText.lowTextStyle.copyWith(
                  color: AppColors.white,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Кнопка закрытия
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: Icon(
                CupertinoIcons.xmark,
                size: 20,
                color: AppColors.greyple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

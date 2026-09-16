// lib/presentation/features/requests/widgets/request_item.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/friend_request.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';

class RequestItem extends StatelessWidget {
  const RequestItem({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
  });

  final FriendRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final user = request.user;
    final displayName = user?.displayName ?? 'Пользователь';
    final subtitle = request.isIncoming
        ? 'Хочет добавить вас в друзья'
        : 'Заявка отправлена';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // 🎯 Динамический фон: тёмно-серый в Dark, светло-серый в Light
        color: AppColors.actionGrey,
        borderRadius: BorderRadius.circular(32),
        // 🎯 Динамическая обводка
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        children: [
          BuildAvatar(url: user?.urlAvatar, wh: 36, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: AppText.mediumTextStyle.copyWith(
                    // 🎯 AppColors.white динамический (белый в Dark, почти чёрный в Light)
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppText.lowTextStyle.copyWith(
                    color: AppColors.greyple,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (request.isIncoming) ...[
            GlassIconButton(
              icon: CupertinoIcons.checkmark,
              filled: true,
              size: 28,
              onTap: onAccept,
            ),
            const SizedBox(width: 8),
          ],
          GlassIconButton(
            icon: CupertinoIcons.xmark,
            size: 28,
            onTap: onReject,
          ),
        ],
      ),
    );
  }
}

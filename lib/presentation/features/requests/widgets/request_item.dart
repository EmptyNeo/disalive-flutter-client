// lib/presentation/features/requests/widgets/request_item.dart
import 'dart:ui';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/friend_request.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';

/// Одна строка списка заявок в друзья — аватар, имя, статус и действия
/// (принять/отклонить входящую, отменить исходящую).
class RequestItem extends StatelessWidget {
  const RequestItem({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
  });

  final FriendRequest request;

  /// Только для входящих заявок.
  final VoidCallback? onAccept;

  /// Отклонить входящую заявку или отменить исходящую — визуально одно и
  /// то же действие (крестик), различается только текстом строки ниже.
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final user = request.user;
    final displayName = user?.displayName ?? 'Пользователь';
    final subtitle = request.isIncoming
        ? 'Хочет добавить вас в друзья'
        : 'Заявка отправлена';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.glassPanelBottom.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              BuildAvatar(url: user?.urlAvatar, wh: 34, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: AppText.mediumTextStyle.copyWith(
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
                  size: 26,
                  onTap: onAccept,
                ),
                const SizedBox(width: 6),
              ],
              GlassIconButton(
                icon: CupertinoIcons.xmark,
                size: 26,
                onTap: onReject,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

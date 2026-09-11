import 'dart:ui';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';

const double _kFloatingPanelMargin = 8;

class ChatHeader extends StatelessWidget {
  final Chat chat;
  final bool isReconnect;
  final VoidCallback? onTap;

  const ChatHeader({
    super.key,
    required this.chat,
    required this.isReconnect,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String title = isReconnect ? "Соединение..." : chat.name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _kFloatingPanelMargin,
        _kFloatingPanelMargin,
        _kFloatingPanelMargin,
        0,
      ),
      child: Row(
        children: [
          GlassIconButton(
            icon: CupertinoIcons.back,
            onTap: () => Navigator.of(context).pop(),
            size: 36,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 6.0,
                    ),
                    child: Row(
                      children: [
                        BuildAvatar(
                          url: chat.urlAvatar,
                          wh: 26,
                          size: 20,
                          status: chat.user?.status,
                          statusSize: 6,
                          isBookmark: chat.isSoloChat ?? false,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: AppText.mediumTextStyle.copyWith(
                              color: AppColors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Кнопка звонка — без фона
          if (chat.isSoloChat == false) ...[
            GlassIconButton(
              icon: CupertinoIcons.phone_fill,
              onTap: () {
                // TODO: Инициализация LiveKit для аудио/видео звонков
              },
              size: 36,
            ),
          ],
        ],
      ),
    );
  }
}
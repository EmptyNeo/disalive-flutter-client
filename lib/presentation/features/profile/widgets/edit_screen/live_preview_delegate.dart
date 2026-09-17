// --- ДЕЛЕГАТ ДЛЯ ЖИВОГО ПРЕДПРОСМОТРА (Без изменений, он уже идеален) ---
import 'dart:io';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/features/profile/items/badge_item.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_avatar.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_banner.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_thoughts_bubble.dart';
import 'package:disalive/presentation/widgets/custom_divider.dart';
import 'package:flutter/cupertino.dart';

import '../../../../../domain/models/badge.dart';

// --- ДЕЛЕГАТ ДЛЯ ЖИВОГО ПРЕДПРОСМОТРА ---
class LivePreviewDelegate extends SliverPersistentHeaderDelegate {
  final String displayName;
  final String username;
  final String aboutMe;
  final String myThink;
  final File? avatarFile;
  final String? avatarUrl;
  final File? bannerFile;
  final String? bannerUrl;
  final Color bannerColor;
  final Color mainColor;
  final Color additionalColor;
  final BadgeModel? badge;
  final double aboutMeHeight;
  final VoidCallback onAvatarTap;
  final VoidCallback onBannerTap;

  LivePreviewDelegate({
    required this.displayName,
    required this.username,
    required this.aboutMe,
    required this.myThink,
    required this.avatarFile,
    required this.avatarUrl,
    required this.bannerFile,
    required this.bannerUrl,
    required this.bannerColor,
    required this.mainColor,
    required this.additionalColor,
    required this.badge,
    required this.aboutMeHeight,
    required this.onAvatarTap,
    required this.onBannerTap,
  });

  @override
  double get minExtent => 150 + aboutMeHeight;

  @override
  double get maxExtent => 190 + aboutMeHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final avatarSize = 70.0 - (progress * 20.0);
    final bannerHeight = 90.0 - (progress * 30.0);
    final pencilPadding = 4.0 - (progress * 2.0);
    final pencilIconSize = 12.0 - (progress * 4.0);

    return Container(
      color: CupertinoColors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 0.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.mainBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        mainColor,
                        mainColor,
                        additionalColor,
                        additionalColor,
                      ],
                      stops: const [0.0, 0.67, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onBannerTap,
                  child: Stack(
                    children: [
                      ProfileBanner(
                        backgroundColor: bannerColor,
                        backgroundImageFile: bannerFile,
                        backgroundImageUrl: bannerUrl,
                        height: bannerHeight,
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Icon(
                            CupertinoIcons.camera_fill,
                            color: CupertinoColors.white.withValues(alpha: 0.7),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: bannerHeight - (avatarSize / 2),
                left: 16,
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ProfileAvatar(
                        url: avatarFile != null ? null : avatarUrl,
                        file: avatarFile,
                        wh: avatarSize,
                        size: avatarSize * 0.5,
                        colorOutline: mainColor,
                      ),
                      Positioned(
                        right: 3,
                        bottom: 3,
                        child: Container(
                          padding: EdgeInsets.all(pencilPadding),
                          decoration: const BoxDecoration(
                            color: AppColors.blurple,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.pencil,
                            color: CupertinoColors.white,
                            size: pencilIconSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: bannerHeight + (avatarSize / 2) + 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayName.isNotEmpty ? displayName : 'Имя',
                          style: AppText.highTextStyle.copyWith(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          BadgeItem(badge: badge!, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${username.isNotEmpty ? username : 'username'}',
                      style: AppText.lowTextStyle.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    if (aboutMe.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          // Легкий полупрозрачный фон для контраста с градиентом
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.divider,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          aboutMe,
                          style: AppText.lowTextStyle.copyWith(
                            color: AppColors.white.withValues(alpha: 0.95),
                            height: 1.4, // Улучшенная читаемость
                            fontWeight: FontWeight.w600
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (myThink.isNotEmpty)
                Positioned(
                  top: bannerHeight - 10,
                  left: 16 + avatarSize + 12,
                  child: ProfileThoughtsBubble(
                    color: mainColor,
                    text: myThink,
                    maxWidth:
                        MediaQuery.of(context).size.width -
                        (16 +
                            avatarSize +
                            12) - // 16 (левый паддинг) + 8 (правый паддинг карточки)
                        24,
                  ),
                ),
              Positioned(
                top: 8,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blurple.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blurple, width: 0.5),
                  ),
                  child: Text(
                    'Предпросмотр',
                    style: TextStyle(
                      color: AppColors.onBlurple,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant LivePreviewDelegate oldDelegate) {
    return oldDelegate.displayName != displayName ||
        oldDelegate.username != username ||
        oldDelegate.aboutMe != aboutMe ||
        oldDelegate.myThink != myThink ||
        oldDelegate.badge?.id != badge?.id ||
        oldDelegate.mainColor != mainColor ||
        oldDelegate.additionalColor != additionalColor ||
        oldDelegate.bannerColor != bannerColor ||
        oldDelegate.aboutMeHeight != aboutMeHeight ||
        oldDelegate.avatarFile?.path != avatarFile?.path ||
        oldDelegate.bannerFile?.path != bannerFile?.path ||
        oldDelegate.avatarUrl != avatarUrl ||
        oldDelegate.bannerUrl != bannerUrl;
  }
}

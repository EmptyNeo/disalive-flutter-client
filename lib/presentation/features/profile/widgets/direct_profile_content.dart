import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/profile/items/badge_item.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_avatar.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_badges_section.dart'; // 🎯 НОВЫЙ ИМПОРТ
import 'package:disalive/presentation/features/profile/widgets/profile_banner.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_info_section.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_thoughts_bubble.dart';
import 'package:disalive/presentation/utils/ui/color_service.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class DirectProfileContent extends StatelessWidget {
  final UserModel user;
  final bool isSoloChat;

  const DirectProfileContent({
    super.key,
    required this.user,
    required this.isSoloChat,
  });

  @override
  Widget build(BuildContext context) {
    final bannerColor = user.pathBanner != null
        ? null
        : ColorService.parseColor(user.bannerColor);

    final profileMainColor = user.bageMainColor != null
        ? ColorService.parseColor(user.bageMainColor)
        : AppColors.mainBackground;

    final profileAdditionalColor = user.bageAdditionalColor != null
        ? ColorService.parseColor(user.bageAdditionalColor)
        : AppColors.mainBackground;
    final badge = user.mainBadge;

    return Stack(
      children: [
        // Фоновый градиент
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  profileMainColor,
                  profileMainColor,
                  profileAdditionalColor,
                  profileAdditionalColor,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // Основной скроллящийся контент
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Верхняя часть: Баннер, Аватар, Мысли
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileBanner(
                    backgroundColor: bannerColor,
                    backgroundImageUrl: user.pathBanner,
                    height: 120,
                  ),
                  Positioned(
                    top: 76,
                    left: 16,
                    child: ProfileAvatar(
                      url: user.urlAvatar,
                      status: user.status,
                      isBookmark: isSoloChat,
                      wh: 80,
                      size: 42,
                      colorOutline: profileMainColor,
                    ),
                  ),
                  if (user.myThink != null && user.myThink!.isNotEmpty)
                    Positioned(
                      top: 100,
                      left: 25 + 80 + 8,
                      child: ProfileThoughtsBubble(
                        color: profileMainColor,
                        text: user.myThink!,
                        maxWidth:
                            MediaQuery.of(context).size.width -
                            (25 + 80 + 8) -
                            24,
                      ),
                    ),
                ],
              ),
            ),

            // Нижняя часть: Имя, Юзернейм, Инфо
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              user.getDisplayName,
                              style: AppText.highTextStyle.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (badge != null) ...[
                              BadgeItem(badge: badge, size: 18),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '@${user.username}',
                                style: AppText.mediumTextStyle.copyWith(
                                  color: AppColors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GlassIconButton(
                              icon: CupertinoIcons.square_fill_on_square_fill,
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: '${user.username}'),
                                );
                                CustomToast.open(
                                  context: context,
                                  icon: CupertinoIcons.checkmark_alt,
                                  color: AppColors.green,
                                  message: 'Имя пользователя скопировано',
                                );
                              },
                              size: 24,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.aboutMe != null &&
                            user.aboutMe!.isNotEmpty) ...[
                          ProfileInfoSection(
                            title: 'ОБО МНЕ',
                            content: user.aboutMe!,
                            icon: CupertinoIcons.chat_bubble_text_fill,
                          ),
                          const SizedBox(height: 8),
                        ],

                        // 🎯 СЕКЦИЯ БЕЙДЖЕЙ (отображается, если список не пуст)
                        if (user.badges != null && user.badges!.isNotEmpty) ...[
                          ProfileBadgesSection(badges: user.badges!),
                          const SizedBox(height: 8),
                        ],

                        ProfileInfoSection(
                          title: 'ДАТА РЕГИСТРАЦИИ',
                          content: user.getDateRegistration,
                          icon: CupertinoIcons.calendar,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

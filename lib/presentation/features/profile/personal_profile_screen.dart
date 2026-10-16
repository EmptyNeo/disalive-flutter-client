import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/features/profile/edit_profile_screen.dart';
import 'package:disalive/presentation/features/profile/items/badge_item.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_action_tile.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_avatar.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_badges_section.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_banner.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_info_section.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_qr_sheet.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_thoughts_bubble.dart';
import 'package:disalive/presentation/utils/ui/color_service.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonalProfileScreen extends StatelessWidget {
  const PersonalProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }

        if (state is ProfileFailure) {
          return Center(
            child: Text(
              'Не удалось загрузить профиль',
              style: AppText.mediumTextStyle.copyWith(color: AppColors.greyple),
            ),
          );
        }

        if (state is ProfileLoaded) {
          return _buildProfileContent(context, state.user);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel user) {
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

    // 🎯 1. ОБЁРТКА В СТИЛЕ SIDEBAR (НО С ИНВЕРТИРОВАННЫМ topRight УГЛОМ)
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(
              28,
            ), // 🎯 Инвертировано: было topLeft, стало topRight
          ),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topRight: Radius.circular(28)),
          child: Stack(
            children: [
              // Фоновый градиент (твоя логика)
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
                      stops: const [0.0, 0.4, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // 🎯 2. КОНТЕНТ С ОРИГИНАЛЬНЫМ ПОЗИЦИОНИРОВАНИЕМ (как ты просил)
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ProfileBanner(
                          backgroundColor: bannerColor,
                          backgroundImageUrl: user.pathBanner,
                          height: 120, // Оставляем как было
                        ),

                        // Аватар (позиция не тронута)
                        Positioned(
                          top: 76,
                          left: 16,
                          child: ProfileAvatar(
                            url: user.urlAvatar,
                            status: user.status,
                            isBookmark: false,
                            wh: 80,
                            size: 42,
                            colorOutline: profileMainColor,
                          ),
                        ),

                        // Кнопка QR-кода (позиция не тронута)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => ProfileQrSheet.show(context, user),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.mainBackground.withValues(
                                  alpha: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                CupertinoIcons.qrcode,
                                color: CupertinoColors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),

                        // Пузырь мыслей (позиция не тронута, динамическая ширина сохранена)
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

                  // Основной контент (DisplayName, Username, Кнопки, Секции)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 50),

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
                                        color: AppColors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GlassIconButton(
                                    icon: CupertinoIcons
                                        .square_fill_on_square_fill,
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

                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProfileActionTile(
                                icon: CupertinoIcons.pencil,
                                title: 'Редактировать профиль',
                                onTap: () {
                                  EditProfileScreen.open(context, user);
                                },
                              ),

                              const SizedBox(height: 8),

                              if (user.aboutMe != null &&
                                  user.aboutMe!.isNotEmpty) ...[
                                ProfileInfoSection(
                                  title: 'ОБО МНЕ',
                                  content: user.aboutMe!,
                                  icon: CupertinoIcons.chat_bubble_text_fill,
                                ),
                                const SizedBox(height: 8),
                              ],

                              if (user.badges != null &&
                                  user.badges!.isNotEmpty) ...[
                                ProfileBadgesSection(badges: user.badges!),
                                const SizedBox(height: 8),
                              ],

                              ProfileInfoSection(
                                title: 'ДАТА РЕГИСТРАЦИИ',
                                content: user.getDateRegistration,
                                icon: CupertinoIcons.calendar,
                              ),

                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

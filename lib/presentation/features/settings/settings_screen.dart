import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/bloc/session/session_bloc.dart';
import 'package:disalive/presentation/bloc/theme/theme_cubit.dart'; // 🎯 Добавлено
import 'package:disalive/presentation/bloc/theme/theme_state.dart'; // 🎯 Добавлено
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/features/settings/screens/privacy_settings_screen.dart';
import 'package:disalive/presentation/features/settings/screens/sessions_settings_screen.dart';
import 'package:disalive/presentation/features/settings/screens/theme_settings_screen.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const double _panelRadius = 28;

  @override
  Widget build(BuildContext context) {
    // 🎯 1. ДОБАВЛЕНО: Слушаем ThemeCubit, чтобы экран перерисовывался при смене темы
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is! ProfileLoaded) {
              return const Center(child: CupertinoActivityIndicator());
            }

            final user = state.user;

            return SafeArea(
              bottom: false,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.elliptical(0, _panelRadius),
                  ),
                  border: Border.symmetric(
                    vertical: BorderSide.none,
                    horizontal: BorderSide(
                      // 🎯 2. ЗАМЕНЕНО: Динамическая рамка вместо белой с альфа-каналом
                      color: AppColors.divider,
                      width: 1,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.elliptical(0, _panelRadius),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          // 🎯 3. ЗАМЕНЕНО: Используем динамические цвета для градиента
                          AppColors.lightGrey.withValues(alpha: 0.72),
                          AppColors.lightGrey.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsHeader(user),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 1,
                          // 🎯 4. ЗАМЕНЕНО: Динамический разделитель
                          color: AppColors.divider,
                        ),
                        Expanded(
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 4),
                              ),

                              _buildNavigationTile(
                                icon: CupertinoIcons.lock_shield_fill,
                                title: 'Конфиденциальность',
                                subtitle: 'Друзья, комментарии, статус в сети',
                                onTap: () {
                                  PrivacySettingsScreen.open(context);
                                },
                              ),

                              const SliverToBoxAdapter(
                                child: SizedBox(height: 4),
                              ),

                              _buildNavigationTile(
                                icon: CupertinoIcons.bell_fill,
                                title: 'Уведомления и звуки',
                                subtitle: 'Push, звуки сообщений и звонков',
                                onTap: () {
                                  // TODO: Открыть экран уведомлений
                                },
                              ),

                              const SliverToBoxAdapter(
                                child: SizedBox(height: 4),
                              ),

                              _buildNavigationTile(
                                icon: CupertinoIcons.device_phone_portrait,
                                title: 'Активные сессии',
                                subtitle:
                                    'Управление входами на других устройствах',
                                onTap: () {
                                  SessionsSettingsScreen.open(context);
                                },
                              ),

                              const SliverToBoxAdapter(
                                child: SizedBox(height: 4),
                              ),

                              _buildNavigationTile(
                                icon: CupertinoIcons.paintbrush_fill,
                                title: 'Тема оформления',
                                subtitle: 'Светлая, тёмная или системная',
                                onTap: () {
                                  ThemeSettingsScreen.open(context);
                                },
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 4),
                              ),
                              _buildNavigationTile(
                                icon: CupertinoIcons.globe,
                                title: 'Язык',
                                subtitle: 'Русский',
                                onTap: () {
                                  // TODO: Открыть экран выбора языка
                                },
                              ),

                              const SliverToBoxAdapter(
                                child: SizedBox(height: 8),
                              ),

                              // --- ВЫХОД ---
                              _buildDestructiveTile(
                                icon: CupertinoIcons.arrow_right_circle_fill,
                                title: 'Выйти из аккаунта',
                                onTap: () {
                                  _showLogoutConfirmation(context);
                                },
                              ),

                              const SliverToBoxAdapter(
                                child: SizedBox(height: 100),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) async {
    final result =
        await showConfirmationDialog(
          context,
          title: "Выйти из аккаунта",
          description:
              "Вам придётся войти снова, чтобы продолжить использование приложения.",
        ) ??
        false;
    if (result) {
      if (context.mounted) {
        final sessionBloc = context.read<SessionBloc>();
        sessionBloc.add(Logout());
      }
    }
  }

  Widget _buildSettingsHeader(UserModel user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Настройки',
            style: TextStyle(
              // AppColors.white уже динамический (белый в Dark, почти чёрный в Light)
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              // TODO: Открыть экран редактирования профиля
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                BuildAvatar(
                  url: user.pathImage,
                  wh: 32,
                  size: 22,
                  status: user.status,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.getDisplayName,
                        style: AppText.mediumTextStyle.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: AppText.lowTextStyle.copyWith(
                          color: AppColors.greyple,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.greyple,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.only(
            left: 16,
            top: 14,
            bottom: 14,
            right: 16,
          ),
          decoration: BoxDecoration(
            // 🎯 5. ЗАМЕНЕНО: Динамический фон карточки
            color: AppColors.actionGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              // 🎯 6. ЗАМЕНЕНО: Динамическая рамка карточки
              color: AppColors.divider,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.blurple, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.mediumTextStyle.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppText.lowTextStyle.copyWith(
                        color: AppColors.greyple,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.greyple,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestructiveTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            // 🎯 7. ЗАМЕНЕНО: Чуть увеличена прозрачность для светлой темы, чтобы было видно
            color: AppColors.errorRed.withValues(
              alpha: AppColors.isDarkMode() ? 0.08 : 0.15,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.errorRed.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.errorRed, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppText.mediumTextStyle.copyWith(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

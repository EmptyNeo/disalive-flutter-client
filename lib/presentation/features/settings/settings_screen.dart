import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const double _panelRadius = 28;

  late bool _canSendMeRequest;
  late bool _allowComments;
  late bool _allowOnlyFriendsComments;
  late bool _followLastVisit;
  late bool _totpEnabled;

  @override
  void initState() {
    super.initState();
    _canSendMeRequest = true;
    _allowComments = true;
    _allowOnlyFriendsComments = false;
    _followLastVisit = true;
    _totpEnabled = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      final user = profileState.user;
      setState(() {
        _canSendMeRequest = user.canSendMeRequest ?? false;
        _allowComments = user.allowComments ?? false;
        _allowOnlyFriendsComments = user.allowOnlyFriendsComments ?? false;
        _followLastVisit = user.followLastVisit ?? false;
        _totpEnabled = user.totpEnabled == 1;
      });
    }
  }

  void _toggleSetting(String field, bool value) {
    setState(() {
      switch (field) {
        case 'canSendMeRequest':
          _canSendMeRequest = value;
          break;
        case 'allowComments':
          _allowComments = value;
          if (!value) _allowOnlyFriendsComments = false;
          break;
        case 'allowOnlyFriendsComments':
          _allowOnlyFriendsComments = value;
          break;
        case 'followLastVisit':
          _followLastVisit = value;
          break;
        case 'totpEnabled':
          _totpEnabled = value;
          break;
      }
    });
    // TODO: Отправить событие в ProfileBloc для сохранения в БД
  }

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.white.withValues(alpha: 0.10),
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
                      color: AppColors.white.withValues(alpha: 0.10),
                    ),
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          const SliverToBoxAdapter(child: SizedBox(height: 16)),

                          _buildSectionTitle('КОНФИДЕНЦИАЛЬНОСТЬ'),
                          _buildSwitchTile(
                            icon: CupertinoIcons.person_badge_plus,
                            title: 'Запросы в друзья',
                            subtitle:
                                'Разрешить пользователям отправлять вам заявки',
                            value: _canSendMeRequest,
                            onChanged: (v) =>
                                _toggleSetting('canSendMeRequest', v),
                          ),
                          _buildSwitchTile(
                            icon: CupertinoIcons.text_bubble,
                            title: 'Комментарии в профиле',
                            subtitle:
                                'Разрешить оставлять комментарии на вашей странице',
                            value: _allowComments,
                            onChanged: (v) =>
                                _toggleSetting('allowComments', v),
                          ),
                          _buildSwitchTile(
                            icon: CupertinoIcons.lock_shield,
                            title: 'Только друзья',
                            subtitle:
                                'Комментировать могут только добавленные в друзья',
                            value: _allowOnlyFriendsComments,
                            isEnabled: _allowComments,
                            onChanged: (v) =>
                                _toggleSetting('allowOnlyFriendsComments', v),
                          ),
                          _buildSwitchTile(
                            icon: CupertinoIcons.clock,
                            title: 'Время последнего посещения',
                            subtitle: 'Показывать, когда вы были в сети',
                            value: _followLastVisit,
                            onChanged: (v) =>
                                _toggleSetting('followLastVisit', v),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 24)),

                          _buildSectionTitle('БЕЗОПАСНОСТЬ'),
                          _buildSwitchTile(
                            icon: CupertinoIcons.lock_fill,
                            title: 'Двухфакторная аутентификация',
                            subtitle: 'Дополнительная защита аккаунта (TOTP)',
                            value: _totpEnabled,
                            onChanged: (v) => _toggleSetting('totpEnabled', v),
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

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Text(
          title,
          style: AppText.lowTextStyle.copyWith(
            color: AppColors.greyple,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isEnabled = true,
  }) {
    final effectiveColor = isEnabled ? AppColors.white : AppColors.greyple;
    final iconColor = AppColors.blurple;

    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: isEnabled ? () => onChanged(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.only(
            left: 16,
            top: 14,
            bottom: 14,
            right: 8,
          ),
          // Чуть компактнее по вертикали
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.white.withValues(alpha: 0.05)
                : AppColors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            // 🎯 ДОБАВЛЕНА ОБВОДКА
            border: Border.all(
              color: isEnabled
                  ? AppColors.white.withValues(alpha: 0.08)
                  : AppColors.white.withValues(alpha: 0.03),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ), // Чуть уменьшил иконку для баланса
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.mediumTextStyle.copyWith(
                        color: effectiveColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppText.lowTextStyle.copyWith(
                        color: isEnabled
                            ? AppColors.greyple
                            : AppColors.greyple.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // 🎯 УМЕНЬШЕННЫЙ SWITCH ЧЕРЕЗ TRANSFORM.SCALE
              Transform.scale(
                scale: 0.85, // Делает переключатель визуально компактнее на 15%
                child: CupertinoSwitch(
                  value: value,
                  onChanged: isEnabled ? onChanged : null,
                  activeTrackColor: AppColors.blurple,
                  inactiveTrackColor: AppColors.greyple.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

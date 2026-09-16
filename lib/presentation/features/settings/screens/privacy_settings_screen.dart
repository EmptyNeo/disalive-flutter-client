import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    final profileBloc = context.read<ProfileBloc>();
    return SwipeToDismissRoute.push(
      context,
      (context) => BlocProvider.value(
        value: profileBloc,
        child: const PrivacySettingsScreen(),
      ),
    );
  }

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late bool _canSendMeRequest;
  late bool _allowComments;
  late bool _allowOnlyFriendsComments;
  late bool _followLastVisit;

  @override
  void initState() {
    super.initState();
    _canSendMeRequest = true;
    _allowComments = true;
    _allowOnlyFriendsComments = false;
    _followLastVisit = true;
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
      }
    });
    // TODO: Отправить событие в ProfileBloc для сохранения в БД
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.mainBackground,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          GlassIconButton(
                            icon: CupertinoIcons.back,
                            onTap: () => Navigator.of(context).pop(),
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Конфиденциальность',
                            style: AppText.highTextStyle,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // --- ДРУЗЬЯ ---
                  _buildSectionTitle('ДРУЗЬЯ'),
                  _buildSwitchTile(
                    icon: CupertinoIcons.person_badge_plus,
                    title: 'Запросы в друзья',
                    subtitle: 'Разрешить пользователям отправлять вам заявки',
                    value: _canSendMeRequest,
                    onChanged: (v) => _toggleSetting('canSendMeRequest', v),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // --- КОММЕНТАРИИ ---
                  _buildSectionTitle('КОММЕНТАРИИ'),
                  _buildSwitchTile(
                    icon: CupertinoIcons.text_bubble,
                    title: 'Комментарии в профиле',
                    subtitle:
                        'Разрешить оставлять комментарии на вашей странице',
                    value: _allowComments,
                    onChanged: (v) => _toggleSetting('allowComments', v),
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

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // --- СТАТУС ---
                  _buildSectionTitle('СТАТУС'),
                  _buildSwitchTile(
                    icon: CupertinoIcons.clock,
                    title: 'Время последнего посещения',
                    subtitle: 'Показывать, когда вы были в сети',
                    value: _followLastVisit,
                    onChanged: (v) => _toggleSetting('followLastVisit', v),
                  ),
                ],
              ),
            ),
          ),
        ),
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
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.white.withValues(alpha: 0.05)
                : AppColors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
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
                child: Icon(icon, color: iconColor, size: 20),
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
              Transform.scale(
                scale: 0.85,
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

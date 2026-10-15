// lib/presentation/features/settings/screens/notification_settings_screen.dart
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/repositories/session_repository.dart';
import 'package:disalive/domain/services/push_notification_service.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    final profileBloc = context.read<ProfileBloc>();
    return SwipeToDismissRoute.push(
      context,
      (context) => BlocProvider.value(
        value: profileBloc,
        child: const NotificationSettingsScreen(),
      ),
    );
  }

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final SessionRepository _sessionRepository = sl<SessionRepository>();

  bool _notificationsEnabled = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      setState(() {
        _notificationsEnabled = profileState.user.hasFcm ?? false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? fcmToken;

      if (value) {
        fcmToken = await PushNotificationService.getToken();

        if (fcmToken == null || fcmToken.isEmpty) {
          if (mounted) {
            CustomToast.open(
              context: context,
              icon: CupertinoIcons.exclamationmark_triangle,
              color: AppColors.errorRed,
              message: 'Не удалось получить токен уведомлений',
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final result = await _sessionRepository.updateFcmToken(fcmToken);

      result.fold(
        (failure) {
          if (mounted) {
            CustomToast.open(
              context: context,
              icon: CupertinoIcons.exclamationmark_triangle,
              color: AppColors.errorRed,
              message: 'Ошибка обновления настроек',
            );
          }
        },
        (success) {
          if (mounted) {
            setState(() {
              _notificationsEnabled = value;
            });

            final profileBloc = context.read<ProfileBloc>();
            final currentState = profileBloc.state;

            if (currentState is ProfileLoaded) {
              final updatedUser = currentState.user.copyWith(hasFcm: value);

              profileBloc.add(UpdateCurrentUser(updatedUser));
            }

            CustomToast.open(
              context: context,
              icon: CupertinoIcons.checkmark_circle,
              color: AppColors.successGreen,
              message: value ? 'Уведомления включены' : 'Уведомления выключены',
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        CustomToast.open(
          context: context,
          icon: CupertinoIcons.exclamationmark_triangle,
          color: AppColors.errorRed,
          message: 'Произошла ошибка',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          _notificationsEnabled = state.user.hasFcm ?? false;
        }

        return CupertinoPageScaffold(
          backgroundColor: CupertinoColors.transparent,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
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
                              Text('Уведомления', style: AppText.highTextStyle),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 8)),

                      _buildSectionTitle('PUSH-УВЕДОМЛЕНИЯ'),

                      _buildSwitchTile(
                        icon: CupertinoIcons.bell_fill,
                        title: 'Включить уведомления',
                        subtitle:
                            'Получать уведомления о новых сообщениях и событиях',
                        value: _notificationsEnabled,
                        isLoading: _isLoading,
                        onChanged: _isLoading ? null : _toggleNotifications,
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      // Информационный блок
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.blurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.blurple.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  CupertinoIcons.info_circle,
                                  color: AppColors.blurple,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Push-уведомления работают только на мобильных устройствах. На веб-версии они недоступны.',
                                    style: AppText.lowTextStyle.copyWith(
                                      color: AppColors.greyple,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    required bool isLoading,
    required ValueChanged<bool>? onChanged,
  }) {
    final isEnabled = onChanged != null;
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
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CupertinoActivityIndicator(color: AppColors.blurple),
                )
              else
                Transform.scale(
                  scale: 0.85,
                  child: CupertinoSwitch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: AppColors.blurple,
                    trackColor: AppColors.divider,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

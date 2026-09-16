// lib/presentation/features/profile/user_profile_screen.dart
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/login.dart';
import 'package:disalive/presentation/features/profile/bloc/profile_bloc.dart';
import 'package:disalive/presentation/features/profile/widgets/direct_profile_content.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_back_button.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserProfileScreen extends StatelessWidget {
  final String username;
  final UserModel? initialUser;

  const UserProfileScreen({
    super.key,
    required this.username,
    this.initialUser,
  });

  static Future<void> open(
    BuildContext context, {
    required String username,
    UserModel? initialUser,
  }) {
    return SwipeToDismissRoute.push(
      context,
      (context) =>
          UserProfileScreen(username: username, initialUser: initialUser),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProfileBloc>()
        ..setupListeners()
        ..add(
          GetProfileByUsername(username: username, initialUser: initialUser),
        ),
      child: const _UserProfileView(),
    );
  }
}

class _UserProfileView extends StatelessWidget {
  const _UserProfileView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is AuthLogoutState) {
          LoginScreen.routeToMe(context);
        }
      },
      builder: (context, state) {
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
                  border: Border.all(color: AppColors.divider, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (state is ProfileLoading)
                        const Center(child: CupertinoActivityIndicator())
                      else if (state is ProfileFailure)
                        Center(
                          child: Text(
                            'Не удалось загрузить профиль',
                            style: TextStyle(
                              color: AppColors.greyple,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else if (state is ProfileLoaded)
                        DirectProfileContent(
                          user: state.user,
                          isSoloChat: false,
                        ),

                      const ProfileBackButton(),
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
}

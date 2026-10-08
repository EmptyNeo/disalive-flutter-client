import 'dart:async';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/data/network/cert_http_overrides.dart';
import 'package:disalive/domain/my_router.dart';
import 'package:disalive/domain/services/emojis_handler.dart';
import 'package:disalive/domain/services/push_notification_service.dart';
import 'package:disalive/presentation/bloc/auth/auth_bloc.dart';
import 'package:disalive/presentation/bloc/theme/theme_cubit.dart';
import 'package:disalive/presentation/bloc/theme/theme_state.dart';
import 'package:disalive/presentation/features/home/home_screen.dart';
import 'package:disalive/presentation/features/login.dart';
import 'package:disalive/presentation/features/register/register_screen.dart';
import 'package:disalive/presentation/features/reset/reset_password_screen.dart';
import 'package:disalive/presentation/features/verify/verify_code_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'presentation/features/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService().init();

  await CertHttpOverrides.init();

  await setupDependencies();

  runApp(const DisaliveApp());

  unawaited(EmojisHandler.instance.initialize());
}

class DisaliveApp extends StatelessWidget {
  const DisaliveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()..loadTheme()),
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(CheckAuthStatus()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              return CupertinoApp(
                navigatorKey: navigatorKey,
                title: 'Disalive',
                theme: themeState.themeData,
                debugShowCheckedModeBanner: false,
                home: _getPage(authState),
                routes: {
                  MyRouter.home: (context) => HomeScreen(),
                  MyRouter.login: (context) => LoginScreen(),
                  MyRouter.register: (context) => RegisterScreen(),
                  MyRouter.resetPassword: (context) => ResetPasswordScreen(),
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _getPage(AuthState state) {
    if (state is AuthLoading || state is AuthInitial) {
      return const SplashScreen();
    }

    if (state is AuthAuthenticated) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}

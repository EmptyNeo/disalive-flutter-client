import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/data/network/cert_http_overrides.dart';
import 'package:disalive/domain/my_router.dart';
import 'package:disalive/domain/services/emojis_handler.dart';
import 'package:disalive/domain/services/push_notification_service.dart';
import 'package:disalive/domain/services/profile_deep_link.dart';
import 'package:disalive/presentation/bloc/auth/auth_bloc.dart';
import 'package:disalive/presentation/bloc/theme/theme_cubit.dart';
import 'package:disalive/presentation/bloc/theme/theme_state.dart';
import 'package:disalive/presentation/features/home/home_screen.dart';
import 'package:disalive/presentation/features/login.dart';
import 'package:disalive/presentation/features/profile/user_profile_screen.dart';
import 'package:disalive/presentation/features/register/register_screen.dart';
import 'package:disalive/presentation/features/reset/reset_password_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'presentation/features/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appLinks = AppLinks();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService().init();

  await CertHttpOverrides.init();

  await setupDependencies();

  runApp(DisaliveApp(appLinks: appLinks));

  unawaited(EmojisHandler.instance.initialize());
}

class DisaliveApp extends StatefulWidget {
  const DisaliveApp({super.key, this.appLinks});

  final AppLinks? appLinks;

  @override
  State<DisaliveApp> createState() => _DisaliveAppState();
}

class _DisaliveAppState extends State<DisaliveApp> {
  late final AuthBloc _authBloc = sl<AuthBloc>()..add(CheckAuthStatus());
  StreamSubscription<Uri>? _linkSubscription;
  String? _pendingProfileUsername;
  bool _navigationScheduled = false;

  @override
  void initState() {
    super.initState();
    _linkSubscription = (widget.appLinks ?? AppLinks()).uriLinkStream.listen(
      _onLink,
    );
  }

  void _onLink(Uri uri) {
    final username = ProfileDeepLink.usernameFrom(uri);
    if (username == null) return;
    _pendingProfileUsername = username;
    _scheduleProfileNavigation();
  }

  void _scheduleProfileNavigation() {
    if (_navigationScheduled || _pendingProfileUsername == null) return;
    _navigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationScheduled = false;
      if (!mounted || _pendingProfileUsername == null) return;
      if (_authBloc.state is! AuthAuthenticated) return;

      final homeContext = HomeScreen.scopeContext;
      if (homeContext == null || !homeContext.mounted) return;

      final username = _pendingProfileUsername!;
      _pendingProfileUsername = null;
      unawaited(UserProfileScreen.open(homeContext, username: username));
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()..loadTheme()),
        BlocProvider<AuthBloc>(create: (_) => _authBloc),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (_, state) =>
                state is AuthAuthenticated || state is AuthUnauthenticated,
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                _scheduleProfileNavigation();
              }
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

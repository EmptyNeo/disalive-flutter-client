import 'package:disalive/app/di/di.dart';
import 'package:disalive/data/network/cert_http_overrides.dart';
import 'package:disalive/domain/my_router.dart';
import 'package:disalive/presentation/bloc/auth/auth_bloc.dart';
import 'package:disalive/presentation/bloc/theme/theme_cubit.dart';
import 'package:disalive/presentation/bloc/theme/theme_state.dart';
import 'package:disalive/presentation/features/home/home_screen.dart';
import 'package:disalive/presentation/features/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'presentation/features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CertHttpOverrides.init();

  await setupDependencies();

  runApp(const DisaliveApp());
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
                title: 'Disalive',
                theme: themeState.themeData,
                debugShowCheckedModeBanner: false,
                home: _getPage(authState),
                routes: {
                  MyRouter.home: (context) => HomeScreen(),
                  MyRouter.login: (context) => LoginScreen(),
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

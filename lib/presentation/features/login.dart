// lib/presentation/screens/login_screen.dart
import 'dart:ui';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/my_router.dart';
import 'package:disalive/presentation/bloc/auth/auth_bloc.dart';
import 'package:disalive/presentation/features/home/home_screen.dart';
import 'package:disalive/presentation/features/register/register_screen.dart';
import 'package:disalive/presentation/features/reset/reset_password_screen.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();

  static void routeToMe(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(MyRouter.login, (route) => false);
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      CustomToast.show(context: context, message: 'Введите email');
      return;
    }

    if (password.isEmpty) {
      CustomToast.show(context: context, message: 'Введите пароль');
      return;
    }

    context.read<AuthBloc>().add(
      LoginButtonPressed(email: email, password: password),
    );
  }

  Widget _buildInputLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          text.toUpperCase(),
          style: AppText.lowTextStyle.copyWith(
            // 🎯 Динамический цвет для второстепенного текста
            color: AppColors.greyple,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  BoxDecoration _glassInputDecoration(bool hasFocus) {
    return BoxDecoration(
      // 🎯 AppColors.actionGrey уже динамический (тёмно-серый / светло-серый)
      color: AppColors.actionGrey,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        // 🎯 Динамическая рамка: blurple при фокусе, divider в покое
        color: hasFocus ? AppColors.blurple : AppColors.divider,
        width: hasFocus ? 1.5 : 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode();

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          CustomToast.show(context: context, message: state.error);
        } else if (state is AuthAuthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            CupertinoPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        return CupertinoPageScaffold(
          backgroundColor: AppColors.mainBackground,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                // 🎯 Фоновые пятна (чуть приглушены для светлой темы)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.1,
                  left: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.blurple.withOpacity(
                        isDark ? 0.45 : 0.25,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blurple.withOpacity(
                            isDark ? 0.45 : 0.25,
                          ),
                          blurRadius: 100,
                          spreadRadius: 50,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.15,
                  right: -100,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.linkBlue.withOpacity(
                        isDark ? 0.35 : 0.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.linkBlue.withOpacity(
                            isDark ? 0.35 : 0.2,
                          ),
                          blurRadius: 100,
                          spreadRadius: 50,
                        ),
                      ],
                    ),
                  ),
                ),

                // 🎯 Стеклянная панель с адаптивными цветами
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            // 🎯 Адаптивный фон стекла: чёрный полупрозрачный или белый полупрозрачный
                            color: isDark
                                ? CupertinoColors.black.withOpacity(0.25)
                                : CupertinoColors.white.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              // 🎯 Адаптивная рамка стекла
                              color: isDark
                                  ? CupertinoColors.white.withOpacity(0.15)
                                  : CupertinoColors.black.withOpacity(0.1),
                              width: 1.5,
                            ),
                            // 🎯 Тень только для светлой темы, чтобы панель "парила"
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: CupertinoColors.black.withOpacity(
                                        0.05,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'С возвращением!',
                                    style: AppText.highTextStyle.copyWith(
                                      // 🎯 AppColors.white динамический (белый в тёмной, почти чёрный в светлой)
                                      color: AppColors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Мы так рады видеть вас снова!',
                                    style: AppText.mediumTextStyle.copyWith(
                                      color: AppColors.greyple,
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 40),

                                  SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      children: [
                                        _buildInputLabel('Email'),
                                        CupertinoTextField(
                                          controller: _emailController,
                                          focusNode: _emailFocus,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          autocorrect: false,
                                          style: AppText.mediumTextStyle
                                              .copyWith(
                                                color: AppColors
                                                    .white, // 🎯 Динамический
                                              ),
                                          cursorColor: AppColors.blurple,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          decoration: _glassInputDecoration(
                                            _emailFocus.hasFocus,
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        _buildInputLabel('Пароль'),
                                        CupertinoTextField(
                                          controller: _passwordController,
                                          focusNode: _passwordFocus,
                                          obscureText: _obscurePassword,
                                          style: AppText.mediumTextStyle
                                              .copyWith(
                                                color: AppColors
                                                    .white, // 🎯 Динамический
                                              ),
                                          cursorColor: AppColors.blurple,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          decoration: _glassInputDecoration(
                                            _passwordFocus.hasFocus,
                                          ),
                                          suffix: CupertinoButton(
                                            padding: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            minSize: 0,
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                            child: Icon(
                                              _obscurePassword
                                                  ? CupertinoIcons.eye_fill
                                                  : CupertinoIcons
                                                        .eye_slash_fill,
                                              size: 20,
                                              // 🎯 Динамическая иконка
                                              color: AppColors.greyple,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minSize: 0,
                                      onPressed: () {
                                        ResetPasswordScreen.open(context);
                                      },
                                      child: Text(
                                        'Забыли пароль?',
                                        style: AppText.mediumTextStyle.copyWith(
                                          color: AppColors.linkBlue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  SizedBox(
                                    width: double.infinity,
                                    child: CupertinoButton.filled(
                                      onPressed: state is AuthLoading
                                          ? null
                                          : _handleLogin,
                                      color: AppColors.blurple,
                                      disabledColor: AppColors.blurple
                                          .withOpacity(0.5),
                                      padding:
                                          AppWidgetStyles.primaryButtonPadding,
                                      borderRadius: BorderRadius.circular(12),
                                      child: state is AuthLoading
                                          ? const CupertinoActivityIndicator(
                                              color: CupertinoColors.white,
                                            )
                                          : Text(
                                              'Войти',
                                              style: AppText.highTextStyle
                                                  .copyWith(
                                                    color:
                                                        CupertinoColors.white,
                                                    fontSize: 16,
                                                  ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Нужна учетная запись?',
                                        style: AppText.mediumTextStyle.copyWith(
                                          color: AppColors.greyple,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          RegisterScreen.open(context);
                                        },
                                        minimumSize: Size(0, 0),
                                        child: Text(
                                          'Зарегистрироваться',
                                          style: AppText.mediumTextStyle
                                              .copyWith(
                                                color: AppColors.linkBlue,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

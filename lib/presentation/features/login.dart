
// lib/presentation/screens/login_screen.dart
import 'dart:ui';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
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
      _showErrorDialog('Введите email');
      return;
    }

    if (password.isEmpty) {
      _showErrorDialog('Введите пароль');
      return;
    }

    context.read<AuthBloc>().add(
      LoginButtonPressed(email: email, password: password),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: CupertinoColors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  BoxDecoration _glassInputDecoration(bool hasFocus) {
    return BoxDecoration(
      color: CupertinoColors.black.withOpacity(0.25),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: hasFocus
            ? AppColors.blurple
            : CupertinoColors.white.withOpacity(0.15),
        width: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          _showErrorDialog(state.error);
        }
      },
      builder: (context, state) {
        return CupertinoPageScaffold(
          backgroundColor: AppColors.mainBackground,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              children: [
                // Фоновые пятна
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.1,
                  left: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.blurple.withOpacity(0.45),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blurple.withOpacity(0.45),
                          blurRadius: 100,
                          spreadRadius: 50,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.1,
                  right: -100,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.linkBlue.withOpacity(0.35),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.linkBlue.withOpacity(0.35),
                          blurRadius: 100,
                          spreadRadius: 50,
                        ),
                      ],
                    ),
                  ),
                ),

                // Полноэкранная стеклянная панель с небольшими отступами
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    // Отступ для видимости рамки
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          // Заполняет весь доступный экран
                          decoration: BoxDecoration(
                            color: CupertinoColors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: CupertinoColors.white.withOpacity(0.15),
                              width: 1.5,
                            ),
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
                                // Применено по центру
                                children: [
                                  Text(
                                    'С возвращением!',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Мы так рады видеть вас снова!',
                                    style: TextStyle(
                                      color: CupertinoColors.white.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 40),

                                  // Блок полей ввода с растягиванием по ширине
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
                                          style: TextStyle(
                                            color: AppColors.white,
                                            fontSize: 16,
                                          ),
                                          cursorColor: AppColors.white,
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
                                          style: TextStyle(
                                            color: AppColors.white,
                                            fontSize: 16,
                                          ),
                                          cursorColor: AppColors.white,
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
                                              color: CupertinoColors.white
                                                  .withOpacity(0.7),
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
                                      onPressed: () {},
                                      child: const Text(
                                        'Забыли пароль?',
                                        style: TextStyle(
                                          color: AppColors.linkBlue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  SizedBox(
                                    width: double.infinity,
                                    child: CupertinoButton(
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
                                          ? const CupertinoActivityIndicator()
                                          : const Text(
                                              'Войти',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: CupertinoColors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Нижний блок также отцентрирован
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .center, // Применено по центру
                                    children: [
                                      Text(
                                        'Нужна учетная запись?',
                                        style: TextStyle(
                                          color: CupertinoColors.white
                                              .withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        minSize: 0,
                                        onPressed: () {},
                                        child: const Text(
                                          'Зарегистрироваться',
                                          style: TextStyle(
                                            color: AppColors.linkBlue,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
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

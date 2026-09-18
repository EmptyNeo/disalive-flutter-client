// lib/presentation/features/register/register_screen.dart
import 'dart:ui';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/my_router.dart';
import 'package:disalive/presentation/features/register/bloc/register_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).pushNamed(MyRouter.register);
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _displayNameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _wasSubmitting = false; // Для отслеживания успешной отправки кода

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _displayNameFocus.addListener(() => setState(() {}));
    _usernameFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _displayNameFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // 🎯 Хелпер для построения лейбла
  Widget _buildInputLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          text.toUpperCase(),
          style: AppText.lowTextStyle.copyWith(
            color: AppColors.greyple,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  // 🎯 Хелпер для стеклянного оформления инпута
  BoxDecoration _glassInputDecoration(bool hasFocus, {bool hasError = false}) {
    return BoxDecoration(
      color: AppColors.actionGrey,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: hasError
            ? AppColors.errorRed
            : (hasFocus ? AppColors.blurple : AppColors.divider),
        width: hasFocus || hasError ? 1.5 : 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode();

    return BlocProvider(
      create: (_) => sl<RegisterBloc>(),
      child: BlocConsumer<RegisterBloc, RegisterState>(
        listener: (context, state) {
          // 1. Синхронизация контроллера с авто-сгенерированным именем пользователя
          if (state.currentStep == 3 &&
              _usernameController.text != state.username) {
            _usernameController.text = state.username;
            _usernameController.selection = TextSelection.fromPosition(
              TextPosition(offset: state.username.length),
            );
          }

          // 2. Отслеживание успешной отправки кода для навигации
          if (_wasSubmitting &&
              !state.isSubmitLoading &&
              state.generalError == null) {
            // 🎯 TODO: Здесь будет навигация на экран ввода кода
            // Navigator.of(context).pushNamed(MyRouter.registerVerify, arguments: state.email);
            print('✅ Код успешно отправлен на ${state.email}');
          }
          _wasSubmitting = state.isSubmitLoading;
        },
        builder: (context, state) {
          return CupertinoPageScaffold(
            backgroundColor: AppColors.mainBackground,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  // 🎯 Фоновые пятна (как в LoginScreen)
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

                  // 🎯 Стеклянная панель
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? CupertinoColors.black.withOpacity(0.25)
                                  : CupertinoColors.white.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? CupertinoColors.white.withOpacity(0.15)
                                    : CupertinoColors.black.withOpacity(0.1),
                                width: 1.5,
                              ),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: CupertinoColors.black
                                            .withOpacity(0.05),
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
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Заголовок меняется в зависимости от шага
                                    Text(
                                      state.currentStep == 1
                                          ? 'Создание аккаунта'
                                          : (state.currentStep == 2
                                                ? 'Как вас зовут?'
                                                : 'Завершение'),
                                      style: AppText.highTextStyle.copyWith(
                                        color: AppColors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      textAlign: TextAlign.start,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      state.currentStep == 1
                                          ? 'Давайте начнём с вашего email'
                                          : (state.currentStep == 2
                                                ? 'Это имя будут видеть другие пользователи'
                                                : 'Придумайте уникальное имя и пароль'),
                                      style: AppText.mediumTextStyle.copyWith(
                                        color: AppColors.greyple,
                                        fontSize: 15,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 40),

                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: _buildCurrentStep(state, context),
                                    ),

                                    const SizedBox(height: 24),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        final bloc = context
                                            .read<RegisterBloc>();
                                        if (bloc.state.currentStep == 1) {
                                          Navigator.of(context).maybePop();
                                        } else {
                                          bloc.add(RegisterGoBack());
                                        }
                                      },
                                      minimumSize: Size(0, 0),
                                      child: Text(
                                        '← Назад',
                                        style: AppText.mediumTextStyle.copyWith(
                                          color: AppColors.greyple,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
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
      ),
    );
  }

  // 🎯 Рендер текущего шага
  Widget _buildCurrentStep(RegisterState state, BuildContext context) {
    switch (state.currentStep) {
      case 1:
        return _buildStep1(state, context);
      case 2:
        return _buildStep2(state, context);
      case 3:
        return _buildStep3(state, context);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- ШАГ 1: Email ---
  Widget _buildStep1(RegisterState state, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          _buildInputLabel('Email'),
          CupertinoTextField(
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            onChanged: (v) =>
                context.read<RegisterBloc>().add(RegisterEmailChanged(v)),
            onEditingComplete: () =>
                context.read<RegisterBloc>().add(RegisterEmailSubmitted()),
            style: AppText.mediumTextStyle.copyWith(color: AppColors.white),
            cursorColor: AppColors.blurple,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: _glassInputDecoration(
              _emailFocus.hasFocus,
              hasError: state.emailError != null,
            ),
          ),

          // 🎯 Анимированная полоска загрузки
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: state.isEmailLoading ? 3.0 : 0.0,
            width: double.infinity,
            color: AppColors.blurple,
            margin: const EdgeInsets.only(top: 4),
          ),

          if (state.emailError != null) ...[
            const SizedBox(height: 8),
            Text(
              state.emailError!,
              style: AppText.lowTextStyle.copyWith(color: AppColors.errorRed),
            ),
          ],

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: state.isEmailLoading
                  ? null
                  : () => context.read<RegisterBloc>().add(
                      RegisterEmailSubmitted(),
                    ),
              color: AppColors.blurple,
              disabledColor: AppColors.blurple.withOpacity(0.5),
              padding: AppWidgetStyles.primaryButtonPadding,
              borderRadius: BorderRadius.circular(12),
              child: state.isEmailLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      ),
                    )
                  : Text(
                      'Далее',
                      style: AppText.highTextStyle.copyWith(
                        color: CupertinoColors.white,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ШАГ 2: Отображаемое имя ---
  Widget _buildStep2(RegisterState state, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          _buildInputLabel('Отображаемое имя'),
          CupertinoTextField(
            controller: _displayNameController,
            focusNode: _displayNameFocus,
            onChanged: (v) =>
                context.read<RegisterBloc>().add(RegisterDisplayNameChanged(v)),
            onEditingComplete: () => context.read<RegisterBloc>().add(
              RegisterDisplayNameSubmitted(),
            ),
            style: AppText.mediumTextStyle.copyWith(color: AppColors.white),
            cursorColor: AppColors.blurple,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: _glassInputDecoration(_displayNameFocus.hasFocus),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () => context.read<RegisterBloc>().add(
                RegisterDisplayNameSubmitted(),
              ),
              color: AppColors.blurple,
              padding: AppWidgetStyles.primaryButtonPadding,
              borderRadius: BorderRadius.circular(12),
              child: Text(
                'Далее',
                style: AppText.highTextStyle.copyWith(
                  color: CupertinoColors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(RegisterState state, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          _buildInputLabel('Имя пользователя'),
          CupertinoTextField(
            controller: _usernameController,
            focusNode: _usernameFocus,
            autocorrect: false,
            onChanged: (v) =>
                context.read<RegisterBloc>().add(RegisterUsernameChanged(v)),
            onEditingComplete: () {
              FocusScope.of(context).unfocus();
              context.read<RegisterBloc>().add(RegisterUsernameCheck());
              Future.delayed(const Duration(milliseconds: 300), () {
                if (state.usernameError == null) _passwordFocus.requestFocus();
              });
            },
            style: AppText.mediumTextStyle.copyWith(color: AppColors.white),
            cursorColor: AppColors.blurple,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: _glassInputDecoration(
              _usernameFocus.hasFocus,
              hasError: state.usernameError != null,
            ),
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: state.isUsernameLoading ? 3.0 : 0.0,
            width: double.infinity,
            color: AppColors.blurple,
            margin: const EdgeInsets.only(top: 4),
          ),

          if (state.usernameError != null) ...[
            const SizedBox(height: 8),
            Text(
              state.usernameError!,
              style: AppText.lowTextStyle.copyWith(color: AppColors.errorRed),
            ),
          ],

          const SizedBox(height: 24),

          _buildInputLabel('Пароль'),
          CupertinoTextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            onChanged: (v) =>
                context.read<RegisterBloc>().add(RegisterPasswordChanged(v)),

            // 🎯 7. ТРИГГЕР: При касании поля пароля сразу запускаем проверку имени,
            // если она ещё не была завершена успешно.
            onTap: () {
              if (state.usernameError != null || !state.isUsernameLoading) {
                context.read<RegisterBloc>().add(RegisterUsernameCheck());
              }
            },

            style: AppText.mediumTextStyle.copyWith(color: AppColors.white),
            cursorColor: AppColors.blurple,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: _glassInputDecoration(_passwordFocus.hasFocus),
            suffix: CupertinoButton(
              padding: const EdgeInsets.only(right: 12),
              minSize: 0,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword
                    ? CupertinoIcons.eye_fill
                    : CupertinoIcons.eye_slash_fill,
                size: 20,
                color: AppColors.greyple,
              ),
            ),
          ),

          if (state.generalError != null) ...[
            const SizedBox(height: 12),
            Text(
              state.generalError!,
              style: AppText.lowTextStyle.copyWith(color: AppColors.errorRed),
            ),
          ],

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              // Блокируем кнопку, если идет загрузка или имя пользователя не проверено/занято
              onPressed:
                  (state.isSubmitLoading ||
                      state.isUsernameLoading ||
                      state.usernameError != null)
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      context.read<RegisterBloc>().add(RegisterSubmitPressed());
                    },
              color: AppColors.blurple,
              disabledColor: AppColors.blurple.withOpacity(0.5),
              padding: AppWidgetStyles.primaryButtonPadding,
              borderRadius: BorderRadius.circular(12),
              child: state.isSubmitLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      ),
                    )
                  : Text(
                      'Отправить код',
                      style: AppText.highTextStyle.copyWith(
                        color: CupertinoColors.white,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

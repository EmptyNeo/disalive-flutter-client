// lib/presentation/features/reset/reset_password_screen.dart

import 'dart:ui';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/email_type.dart';
import 'package:disalive/domain/my_router.dart';
import 'package:disalive/presentation/features/reset/bloc/reset_password_bloc.dart';
import 'package:disalive/presentation/features/verify/verify_code_screen.dart';
import 'package:disalive/presentation/widgets/step_progress_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).pushNamed(MyRouter.resetPassword);
  }

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _verifyPasswordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  final _verifyPasswordFocus = FocusNode();

  bool _obscureNewPassword = true;
  bool _obscureVerifyPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _verifyPasswordController.dispose();
    _emailFocus.dispose();
    _newPasswordFocus.dispose();
    _verifyPasswordFocus.dispose();
    super.dispose();
  }

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
      create: (_) => sl<ResetPasswordBloc>(),
      child: BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
        listener: (context, state) {
          // 🎯 Навигация на экран ввода кода при успешной валидации паролей
          if (state.isReadyToVerify) {
            VerifyCodeScreen.open(
              context: context,
              email: state.email,
              emailType: EmailType.reset,
              newPassword: state.newPassword,
              verifyPassword: state.verifyPassword,
            );
            // Сбрасываем флаг, чтобы при возврате назад не триггерить навигацию снова
            context.read<ResetPasswordBloc>().add(
              ResetReset(state.email, state.newPassword, state.verifyPassword),
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
                  // Фоновые пятна
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
                                    StepProgressIndicator(
                                      totalSteps: 2,
                                      currentStep: state.currentStep,
                                    ),
                                    const SizedBox(height: 24),

                                    Text(
                                      state.currentStep == 1
                                          ? 'Начало восстановления'
                                          : 'Новый пароль',
                                      style: AppText.highTextStyle.copyWith(
                                        color: AppColors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      textAlign: TextAlign.start,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      state.currentStep == 1
                                          ? 'Введите email, привязанный к аккаунту'
                                          : 'Придумайте надёжный пароль для входа',
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
                                      child: KeyedSubtree(
                                        key: ValueKey(state.currentStep),
                                        child: state.currentStep == 1
                                            ? _buildStep1(state, context)
                                            : _buildStep2(state, context),
                                      ),
                                    ),

                                    const SizedBox(height: 24),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        final bloc = context
                                            .read<ResetPasswordBloc>();
                                        if (bloc.state.currentStep == 1) {
                                          Navigator.of(context).maybePop();
                                        } else {
                                          bloc.add(ResetGoBack());
                                        }
                                      },
                                      minimumSize: const Size(0, 0),
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

  Widget _buildStep1(ResetPasswordState state, BuildContext context) {
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
                context.read<ResetPasswordBloc>().add(ResetEmailChanged(v)),
            onEditingComplete: () =>
                context.read<ResetPasswordBloc>().add(ResetEmailSubmitted()),
            style: AppText.mediumTextStyle.copyWith(color: AppColors.white),
            cursorColor: AppColors.blurple,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: _glassInputDecoration(
              _emailFocus.hasFocus,
              hasError: state.emailError != null,
            ),
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
              onPressed: state.isLoading
                  ? null
                  : () => context.read<ResetPasswordBloc>().add(
                      ResetEmailSubmitted(),
                    ),
              color: AppColors.blurple,
              disabledColor: AppColors.blurple.withOpacity(0.5),
              padding: AppWidgetStyles.primaryButtonPadding,
              borderRadius: BorderRadius.circular(12),
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      ),
                    )
                  : const Text(
                      'Далее',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ResetPasswordState state, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          _buildInputLabel('Новый пароль'),
          CupertinoTextField(
            controller: _newPasswordController,
            focusNode: _newPasswordFocus,
            obscureText: _obscureNewPassword,
            onChanged: (v) => context.read<ResetPasswordBloc>().add(
              ResetNewPasswordChanged(v),
            ),
            style: AppText.mediumTextStyle.copyWith(color: AppColors.white),
            cursorColor: AppColors.blurple,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: _glassInputDecoration(
              _newPasswordFocus.hasFocus,
              hasError: state.passwordError != null,
            ),
            suffix: CupertinoButton(
              padding: const EdgeInsets.only(right: 12),
              minSize: 0,
              onPressed: () =>
                  setState(() => _obscureNewPassword = !_obscureNewPassword),
              child: Icon(
                _obscureNewPassword
                    ? CupertinoIcons.eye_fill
                    : CupertinoIcons.eye_slash_fill,
                size: 20,
                color: AppColors.greyple,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildInputLabel('Подтвердите пароль'),
          CupertinoTextField(
            controller: _verifyPasswordController,
            focusNode: _verifyPasswordFocus,
            obscureText: _obscureVerifyPassword,
            onChanged: (v) => context.read<ResetPasswordBloc>().add(
              ResetVerifyPasswordChanged(v),
            ),
            onEditingComplete: () =>
                context.read<ResetPasswordBloc>().add(ResetSubmitPressed()),
            style: AppText.mediumTextStyle.copyWith(color: AppColors.white),
            cursorColor: AppColors.blurple,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: _glassInputDecoration(
              _verifyPasswordFocus.hasFocus,
              hasError: state.passwordError != null,
            ),
            suffix: CupertinoButton(
              padding: const EdgeInsets.only(right: 12),
              minSize: 0,
              onPressed: () => setState(
                () => _obscureVerifyPassword = !_obscureVerifyPassword,
              ),
              child: Icon(
                _obscureVerifyPassword
                    ? CupertinoIcons.eye_fill
                    : CupertinoIcons.eye_slash_fill,
                size: 20,
                color: AppColors.greyple,
              ),
            ),
          ),
          if (state.passwordError != null) ...[
            const SizedBox(height: 8),
            Text(
              state.passwordError!,
              style: AppText.lowTextStyle.copyWith(color: AppColors.errorRed),
            ),
          ],
          const SizedBox(height: 32),

          // 🎯 ОБНОВЛЕННАЯ КНОПКА С ИНДИКАТОРОМ ЗАГРУЗКИ
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: state.isLoading
                  ? null
                  : () => context.read<ResetPasswordBloc>().add(
                      ResetSubmitPressed(),
                    ),
              color: AppColors.blurple,
              disabledColor: AppColors.blurple.withOpacity(0.5),
              // 🎯 Визуально показываем неактивность
              padding: AppWidgetStyles.primaryButtonPadding,
              borderRadius: BorderRadius.circular(12),
              child: state.isLoading
                  ? const SizedBox(
                      // 🎯 Показываем спиннер
                      height: 20,
                      width: 20,
                      child: CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      ),
                    )
                  : const Text(
                      'Отправить код',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

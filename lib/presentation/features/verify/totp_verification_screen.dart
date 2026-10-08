import 'dart:ui';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/my_router.dart';
import 'package:disalive/presentation/bloc/auth/auth_bloc.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TotpVerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final String? fcmToken;

  const TotpVerificationScreen({
    super.key,
    required this.email,
    required this.password,
    required this.fcmToken,
  });

  @override
  State<TotpVerificationScreen> createState() => _TotpVerificationScreenState();
}

class _TotpVerificationScreenState extends State<TotpVerificationScreen> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _isDark = AppColors.isDarkMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isEmpty) {
      if (index > 0) _focusNodes[index - 1].requestFocus();
      _controllers[index].clear();
      return;
    }

    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.isEmpty) return;

    // Обработка вставки
    if (cleanValue.length > 1) {
      final codeToPaste = cleanValue.length > 6
          ? cleanValue.substring(0, 6)
          : cleanValue;
      for (int i = 0; i < codeToPaste.length; i++) {
        _controllers[i].text = codeToPaste[i];
      }
      final nextFocusIndex = codeToPaste.length < 6 ? codeToPaste.length : 5;
      _focusNodes[nextFocusIndex].requestFocus();
      return;
    }

    // Обычный ввод
    _controllers[index].text = cleanValue[0];
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  KeyEventResult _handleBackspaceOnEmpty(int index, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_controllers[index].text.isNotEmpty || index == 0) {
      return KeyEventResult.ignored;
    }

    final previousIndex = index - 1;
    _controllers[previousIndex].clear();
    _focusNodes[previousIndex].requestFocus();
    return KeyEventResult.handled;
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();

  void _handleVerify() {
    FocusScope.of(context).unfocus();
    if (_enteredCode.length == 6) {
      context.read<AuthBloc>().add(
        VerifyTotpButtonPressed(
          widget.email,
          widget.password,
          _enteredCode,
          widget.fcmToken,
        ),
      );
    } else {
      CustomToast.show(context: context, message: 'Введите все 6 цифр');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          CustomToast.show(context: context, message: state.error);
          // Очищаем поля при ошибке
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes.first.requestFocus();
        } else if (state is AuthAuthenticated) {
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            MyRouter.home, // Или MyRouter.login, если home еще не настроен
            (route) => false,
          );
        }
      },
      child: CupertinoPageScaffold(
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
                    color: AppColors.blurple.withValues(
                      alpha: _isDark ? 0.45 : 0.25,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blurple.withValues(
                          alpha: _isDark ? 0.45 : 0.25,
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
                    color: AppColors.linkBlue.withValues(
                      alpha: _isDark ? 0.35 : 0.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.linkBlue.withValues(
                          alpha: _isDark ? 0.35 : 0.2,
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
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: _isDark
                              ? CupertinoColors.black.withValues(alpha: 0.25)
                              : CupertinoColors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isDark
                                ? CupertinoColors.white.withValues(alpha: 0.15)
                                : CupertinoColors.black.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                          boxShadow: _isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: CupertinoColors.black.withValues(
                                      alpha: 0.05,
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
                                // Иконка щита/ключа
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.blurple.withValues(
                                      alpha: 0.15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.lock_shield_fill,
                                    color: AppColors.blurple,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                Text(
                                  'Двухфакторная аутентификация',
                                  style: AppText.highTextStyle.copyWith(
                                    color: AppColors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Введите 6-значный код из вашего приложения-аутентификатора',
                                  style: AppText.mediumTextStyle.copyWith(
                                    color: AppColors.greyple,
                                    fontSize: 15,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 40),

                                // 6 полей ввода
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(6, (index) {
                                    return Expanded(
                                      child: Container(
                                        height: 50, // Чуть выше для удобства
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        child: Focus(
                                          onKeyEvent: (node, event) =>
                                              _handleBackspaceOnEmpty(
                                                index,
                                                event,
                                              ),
                                          child: CupertinoTextField(
                                            controller: _controllers[index],
                                            focusNode: _focusNodes[index],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            textAlignVertical:
                                                TextAlignVertical.center,
                                            style: AppText.highTextStyle
                                                .copyWith(
                                                  color: AppColors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            cursorColor: AppColors.blurple,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              color: AppColors.actionGrey,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    _focusNodes[index].hasFocus
                                                    ? AppColors.blurple
                                                    : AppColors.divider,
                                                width:
                                                    _focusNodes[index].hasFocus
                                                    ? 2.0
                                                    : 1.0,
                                              ),
                                            ),
                                            onChanged: (value) =>
                                                _onDigitChanged(index, value),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),

                                const SizedBox(height: 48),

                                // Кнопка подтверждения
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    final isVerifying =
                                        state is AuthTotpVerifying;
                                    return SizedBox(
                                      width: double.infinity,
                                      child: CupertinoButton.filled(
                                        onPressed: isVerifying
                                            ? null
                                            : _handleVerify,
                                        color: AppColors.blurple,
                                        disabledColor: AppColors.blurple
                                            .withValues(alpha: 0.5),
                                        padding: AppWidgetStyles
                                            .primaryButtonPadding,
                                        borderRadius: BorderRadius.circular(12),
                                        child: isVerifying
                                            ? const CupertinoActivityIndicator(
                                                color: CupertinoColors.white,
                                              )
                                            : const Text(
                                                'Подтвердить',
                                                style: TextStyle(
                                                  color: CupertinoColors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 24),

                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => Navigator.of(context).pop(),
                                  minimumSize: Size(0, 0),
                                  child: Text(
                                    'Вернуться к входу',
                                    style: AppText.mediumTextStyle.copyWith(
                                      color: AppColors.linkBlue,
                                      fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

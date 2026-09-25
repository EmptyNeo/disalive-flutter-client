import 'dart:async';
import 'dart:ui';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/email_type.dart';
import 'package:disalive/domain/my_router.dart';
import 'package:disalive/presentation/features/verify/bloc/verify_code_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;
  final EmailType emailType;
  final String? newPassword;
  final String? verifyPassword;
  final String? username;
  final String? displayName;
  final String? password;

  const VerifyCodeScreen({
    super.key,
    required this.email,
    required this.emailType,
    this.newPassword,
    this.verifyPassword,
    this.username,
    this.displayName,
    this.password,
  });

  static Future<void> open({
    required BuildContext context,
    required String email,
    required EmailType emailType,
    String? newPassword,
    String? verifyPassword,
    String? username,
    String? displayName,
    String? password,
  }) {
    return Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => sl<VerifyCodeBloc>(),
          child: VerifyCodeScreen(
            email: email,
            emailType: emailType,
            newPassword: newPassword,
            verifyPassword: verifyPassword,
            username: username,
            displayName: displayName,
            password: password,
          ),
        ),
      ),
    );
  }

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
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
      if (!mounted) return;

      context.read<VerifyCodeBloc>().add(
        VerifyCodeInit(
          email: widget.email,
          emailType: widget.emailType,
          newPassword: widget.newPassword,
          verifyPassword: widget.verifyPassword,
          username: widget.username,
          displayName: widget.displayName,
          password: widget.password,
        ),
      );

      _focusNodes.first.requestFocus();
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
    // 1. Обработка Backspace (поле стало пустым)
    if (value.isEmpty) {
      context.read<VerifyCodeBloc>().add(VerifyCodeDigitChanged(index, ''));
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }

    // 2. Оставляем только цифры
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.isEmpty) return;

    // 3. 🎯 ОБРАБОТКА ВСТАВКИ (длина больше 1)
    if (cleanValue.length > 1) {
      // Берем максимум 6 цифр
      final codeToPaste = cleanValue.length > 6
          ? cleanValue.substring(0, 6)
          : cleanValue;

      // Отправляем в BLoC
      context.read<VerifyCodeBloc>().add(VerifyCodePasted(codeToPaste));

      // Обновляем контроллеры, чтобы отобразить вставленное
      for (int i = 0; i < codeToPaste.length; i++) {
        _controllers[i].text = codeToPaste[i];
      }

      // Переносим фокус на последнюю заполненную ячейку (или следующую пустую)
      final nextFocusIndex = codeToPaste.length < 6 ? codeToPaste.length : 5;
      _focusNodes[nextFocusIndex].requestFocus();

      return; // Прерываем выполнение, чтобы не сработала логика одиночного ввода
    }

    // 4. 🎯 ОБРАБОТКА ОБЫЧНОГО ВВОДА (длина == 1)
    final char = cleanValue[0];

    // Защита от дублирования событий (если значение уже установлено через BlocListener)
    if (context.read<VerifyCodeBloc>().state.codeDigits[index] == char) {
      return;
    }

    context.read<VerifyCodeBloc>().add(VerifyCodeDigitChanged(index, char));

    // Переход к следующей ячейке
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  // Backspace на УЖЕ пустой клетке не меняет её текст ('' -> ''), поэтому
  // onChanged у CupertinoTextField в этом случае вообще не вызывается —
  // само нажатие клавиши нужно ловить отдельно, через Focus.onKeyEvent,
  // который видит клавишу независимо от того, поменялся текст или нет.
  KeyEventResult _handleBackspaceOnEmpty(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_controllers[index].text.isNotEmpty || index == 0) {
      return KeyEventResult.ignored;
    }

    // Как в нативном iOS-вводе кода: backspace на пустой клетке стирает
    // цифру в предыдущей и переводит фокус на неё — одно нажатие вместо двух.
    final previousIndex = index - 1;
    _controllers[previousIndex].clear();
    context.read<VerifyCodeBloc>().add(
      VerifyCodeDigitChanged(previousIndex, ''),
    );
    _focusNodes[previousIndex].requestFocus();

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VerifyCodeBloc, VerifyCodeState>(
      listener: (context, state) {
        for (int i = 0; i < 6; i++) {
          if (_controllers[i].text != state.codeDigits[i]) {
            _controllers[i].text = state.codeDigits[i];
          }
        }

        if (state.isSuccess) {
          if (!mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(MyRouter.login, (route) => false);
          });
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.mainBackground,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              // Фоновые пятна (как в Login/Register)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.1,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blurple.withOpacity(_isDark ? 0.45 : 0.25),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blurple.withOpacity(
                          _isDark ? 0.45 : 0.25,
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
                    color: AppColors.linkBlue.withOpacity(_isDark ? 0.35 : 0.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.linkBlue.withOpacity(
                          _isDark ? 0.35 : 0.2,
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
                              ? CupertinoColors.black.withOpacity(0.25)
                              : CupertinoColors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isDark
                                ? CupertinoColors.white.withOpacity(0.15)
                                : CupertinoColors.black.withOpacity(0.1),
                            width: 1.5,
                          ),
                          boxShadow: _isDark
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
                        child: BlocBuilder<VerifyCodeBloc, VerifyCodeState>(
                          builder: (context, state) {
                            return Center(
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
                                      'Подтверждение email',
                                      style: AppText.highTextStyle.copyWith(
                                        color: AppColors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Введите 6-значный код из письма',
                                      style: AppText.mediumTextStyle.copyWith(
                                        color: AppColors.greyple,
                                        fontSize: 15,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 40),

                                    // 🎯 6 полей ввода
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(6, (index) {
                                        return Expanded(
                                          child: Container(
                                            height: 42,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 2,
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
                                                keyboardType:
                                                    TextInputType.number,
                                                textAlign: TextAlign.center,
                                                textAlignVertical:
                                                    TextAlignVertical.center,
                                                // 🎯 Вертикальное центрирование
                                                style: AppText.highTextStyle
                                                    .copyWith(
                                                      color: AppColors.white,
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                cursorColor: AppColors.blurple,
                                                padding: EdgeInsets.zero,
                                                // 🎯 Убираем стандартные отступы
                                                decoration: BoxDecoration(
                                                  color: AppColors.actionGrey,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color:
                                                        _focusNodes[index]
                                                            .hasFocus
                                                        ? AppColors.blurple
                                                        : AppColors.divider,
                                                    width:
                                                        _focusNodes[index]
                                                            .hasFocus
                                                        ? 2.0
                                                        : 1.0,
                                                  ),
                                                ),
                                                onChanged: (value) =>
                                                    _onDigitChanged(
                                                      index,
                                                      value,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),

                                    if (state.error != null) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        state.error!,
                                        style: AppText.lowTextStyle.copyWith(
                                          color: AppColors.errorRed,
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 24),

                                    Text(
                                      'Код отправлен на',
                                      style: AppText.mediumTextStyle.copyWith(
                                        color: AppColors.greyple,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.blurple.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        state.email,
                                        style: AppText.mediumTextStyle.copyWith(
                                          color: AppColors.blurple,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 40),

                                    Text(
                                      'Не получили код?',
                                      style: AppText.mediumTextStyle.copyWith(
                                        color: AppColors.greyple,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: CupertinoButton(
                                        onPressed:
                                            state.resendTimer > 0 ||
                                                state.isLoading
                                            ? null
                                            : () {
                                                context
                                                    .read<VerifyCodeBloc>()
                                                    .add(
                                                      ResendCodePressed(
                                                        state.email,
                                                        state.emailType,
                                                        state.username,
                                                        state.password,
                                                      ),
                                                    );
                                              },
                                        color: AppColors.actionGrey,
                                        borderRadius: BorderRadius.circular(12),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // 🎯 Показываем лоадер, если идёт отправка
                                            if (state.isLoading) ...[
                                              const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CupertinoActivityIndicator(
                                                      color: AppColors.blurple,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text('Отправка...'),
                                            ] else ...[
                                              Icon(
                                                CupertinoIcons.refresh,
                                                color: state.resendTimer > 0
                                                    ? AppColors.greyple
                                                    : AppColors.blurple,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                state.resendTimer > 0
                                                    ? 'Отправить код повторно (${state.resendTimer})'
                                                    : 'Отправить код повторно',
                                                style: AppText.mediumTextStyle
                                                    .copyWith(
                                                      color:
                                                          state.resendTimer > 0
                                                          ? AppColors.greyple
                                                          : AppColors.blurple,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minSize: 0,
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text(
                                        widget.emailType ==
                                                EmailType.confirmRegister
                                            ? 'Вернуться к регистрации'
                                            : 'Вернуться к восстановлению',
                                        style: AppText.mediumTextStyle.copyWith(
                                          color: AppColors.linkBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

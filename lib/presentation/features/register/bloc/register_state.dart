// lib/presentation/features/register/bloc/register_state.dart

part of 'register_bloc.dart';

class RegisterState extends Equatable {
  final int currentStep;
  final String email;
  final String displayName;
  final String username;
  final String password;

  final bool isEmailLoading;
  final bool isUsernameLoading;
  final bool isSubmitLoading;

  // 🎯 НОВОЕ: Флаг успешной отправки кода
  final bool isCodeSent;

  final String? emailError;
  final String? usernameError;
  final String? generalError;

  const RegisterState({
    this.currentStep = 1,
    this.email = '',
    this.displayName = '',
    this.username = '',
    this.password = '',
    this.isEmailLoading = false,
    this.isUsernameLoading = false,
    this.isSubmitLoading = false,
    this.isCodeSent = false, // 🎯 По умолчанию false
    this.emailError,
    this.usernameError,
    this.generalError,
  });

  RegisterState copyWith({
    int? currentStep,
    String? email,
    String? displayName,
    String? username,
    String? password,
    bool? isEmailLoading,
    bool? isUsernameLoading,
    bool? isSubmitLoading,
    bool? isCodeSent, // 🎯 Добавляем в copyWith
    String? emailError,
    String? usernameError,
    String? generalError,
  }) {
    return RegisterState(
      currentStep: currentStep ?? this.currentStep,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      password: password ?? this.password,
      isEmailLoading: isEmailLoading ?? this.isEmailLoading,
      isUsernameLoading: isUsernameLoading ?? this.isUsernameLoading,
      isSubmitLoading: isSubmitLoading ?? this.isSubmitLoading,
      isCodeSent: isCodeSent ?? this.isCodeSent,
      emailError: emailError,
      usernameError: usernameError,
      generalError: generalError,
    );
  }

  @override
  List<Object?> get props => [
    currentStep, email, displayName, username, password,
    isEmailLoading, isUsernameLoading, isSubmitLoading,
    isCodeSent, // 🎯 Добавляем в props
    emailError, usernameError, generalError,
  ];
}

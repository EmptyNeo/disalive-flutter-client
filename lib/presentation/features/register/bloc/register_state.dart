// lib/presentation/features/register/bloc/register_state.dart

part of 'register_bloc.dart';

class RegisterState extends Equatable {
  final int currentStep; // 1: Email, 2: DisplayName, 3: Username & Password
  final String email;
  final String displayName;
  final String username;
  final String password;

  // Индикаторы загрузки
  final bool isEmailLoading;
  final bool isUsernameLoading;
  final bool isSubmitLoading;

  // Ошибки валидации
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
      emailError: emailError,
      usernameError: usernameError,
      generalError: generalError,
    );
  }

  @override
  List<Object?> get props => [
    currentStep, email, displayName, username, password,
    isEmailLoading, isUsernameLoading, isSubmitLoading,
    emailError, usernameError, generalError,
  ];
}
// lib/presentation/features/reset/bloc/reset_password_state.dart
part of 'reset_password_bloc.dart';

class ResetPasswordState extends Equatable {
  final int currentStep; // 1: Email, 2: Passwords
  final String email;
  final String newPassword;
  final String verifyPassword;
  final bool isLoading;
  final String? emailError;
  final String? passwordError;
  final bool isReadyToVerify; // Флаг для навигации на экран кода

  const ResetPasswordState({
    this.currentStep = 1,
    this.email = '',
    this.newPassword = '',
    this.verifyPassword = '',
    this.isLoading = false,
    this.emailError,
    this.passwordError,
    this.isReadyToVerify = false,
  });

  ResetPasswordState copyWith({
    int? currentStep,
    String? email,
    String? newPassword,
    String? verifyPassword,
    bool? isLoading,
    String? emailError,
    String? passwordError,
    bool? isReadyToVerify,
  }) {
    return ResetPasswordState(
      currentStep: currentStep ?? this.currentStep,
      email: email ?? this.email,
      newPassword: newPassword ?? this.newPassword,
      verifyPassword: verifyPassword ?? this.verifyPassword,
      isLoading: isLoading ?? this.isLoading,
      emailError: emailError,
      passwordError: passwordError,
      isReadyToVerify: isReadyToVerify ?? this.isReadyToVerify,
    );
  }

  @override
  List<Object?> get props => [
    currentStep, email, newPassword, verifyPassword, isLoading,
    emailError, passwordError, isReadyToVerify,
  ];
}
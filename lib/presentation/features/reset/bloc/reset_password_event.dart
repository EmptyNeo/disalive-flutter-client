// lib/presentation/features/reset/bloc/reset_password_event.dart

part of 'reset_password_bloc.dart';

abstract class ResetPasswordEvent extends Equatable {
  const ResetPasswordEvent();

  @override
  List<Object?> get props => [];
}

class ResetEmailChanged extends ResetPasswordEvent {
  final String email;

  const ResetEmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

class ResetEmailSubmitted extends ResetPasswordEvent {}

class ResetNewPasswordChanged extends ResetPasswordEvent {
  final String password;

  const ResetNewPasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

class ResetVerifyPasswordChanged extends ResetPasswordEvent {
  final String password;

  const ResetVerifyPasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

class ResetSubmitPressed extends ResetPasswordEvent {}

class ResetGoBack extends ResetPasswordEvent {}

class ResetReset extends ResetPasswordEvent {
  final String email;
  final String newPassword;
  final String verifyPassword;

  const ResetReset(this.email, this.newPassword, this.verifyPassword);
}

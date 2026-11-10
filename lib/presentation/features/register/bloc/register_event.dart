// lib/presentation/features/register/bloc/register_event.dart

part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

// --- Шаг 1: Email ---
class RegisterEmailChanged extends RegisterEvent {
  final String email;

  const RegisterEmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

class RegisterEmailSubmitted extends RegisterEvent {}

// --- Шаг 2: Отображаемое имя ---
class RegisterDisplayNameChanged extends RegisterEvent {
  final String displayName;

  const RegisterDisplayNameChanged(this.displayName);

  @override
  List<Object?> get props => [displayName];
}

class RegisterDisplayNameSubmitted extends RegisterEvent {}

class RegisterBirthDateChanged extends RegisterEvent {
  final String dateOfBirth;

  const RegisterBirthDateChanged(this.dateOfBirth);

  @override
  List<Object?> get props => [dateOfBirth];
}

// --- Шаг 3: Имя пользователя и Пароль ---
class RegisterUsernameChanged extends RegisterEvent {
  final String username;

  const RegisterUsernameChanged(this.username);

  @override
  List<Object?> get props => [username];
}

// 🎯 Событие для проверки имени пользователя (вызывается при onEditingComplete или потере фокуса)
class RegisterUsernameCheck extends RegisterEvent {}

class RegisterPasswordChanged extends RegisterEvent {
  final String password;

  const RegisterPasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

class RegisterSubmitPressed extends RegisterEvent {}

class RegisterReset extends RegisterEvent {}

class RegisterGoBack extends RegisterEvent {}

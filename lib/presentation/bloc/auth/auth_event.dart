part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent {}

class LoginButtonPressed extends AuthEvent {
  final String email;
  final String password;

  LoginButtonPressed({required this.email, required this.password});
}

class CheckAuthStatus extends AuthEvent {}

class AuthLogout extends AuthEvent {}

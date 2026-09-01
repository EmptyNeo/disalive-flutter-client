part of 'auth_bloc.dart';

@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthTotpRequired extends AuthState {
  AuthTotpRequired();
}

class AuthAuthenticated extends AuthState {
  final String? keySession;

  AuthAuthenticated({this.keySession});
}

class AuthUnauthenticated extends AuthState {}

class AuthRequireTotp extends AuthState {}

class AuthFailure extends AuthState {
  final String error;

  AuthFailure({required this.error});
}

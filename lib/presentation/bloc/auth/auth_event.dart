part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent {}

class LoginButtonPressed extends AuthEvent {
  final String email;
  final String password;
  final String? fcmToken;

  LoginButtonPressed({
    required this.email,
    required this.password,
    required this.fcmToken,
  });
}

class VerifyTotpButtonPressed extends AuthEvent {
  final String email;
  final String password;
  final String totpCode;
  final String? fcmToken;

  VerifyTotpButtonPressed(
    this.email,
    this.password,
    this.totpCode,
    this.fcmToken,
  );
}

class CheckAuthStatus extends AuthEvent {}

class AuthLogout extends AuthEvent {}

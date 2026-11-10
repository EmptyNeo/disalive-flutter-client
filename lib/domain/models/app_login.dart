// lib/domain/models/app_login.dart

class AppLogin {
  bool requireTotp;
  String keySession;
  bool accountBanned;

  AppLogin({
    required this.requireTotp,
    required this.keySession,
    this.accountBanned = false,
  });
}

// lib/domain/models/app_login.dart

class AppLogin {
  bool requireTotp;
  String keySession;

  AppLogin({required this.requireTotp, required this.keySession});
}

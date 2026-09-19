part of 'verify_code_bloc.dart';

class VerifyCodeState extends Equatable {
  final String email;
  final EmailType emailType;
  final List<String> codeDigits;
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final int resendTimer;
  final String? newPassword;
  final String? verifyPassword;
  final String? username;
  final String? displayName;
  final String? password;

  const VerifyCodeState({
    this.email = '',
    this.emailType = EmailType.confirmRegister,
    this.codeDigits = const ['', '', '', '', '', ''],
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.resendTimer = 60,
    this.newPassword,
    this.verifyPassword,
    this.username,
    this.displayName,
    this.password,
  });

  VerifyCodeState copyWith({
    String? email,
    EmailType? emailType,
    List<String>? codeDigits,
    bool? isLoading,
    bool? isSuccess,
    String? error,
    int? resendTimer,
    String? newPassword,
    String? verifyPassword,
    String? username,
    String? displayName,
    String? password,
  }) {
    return VerifyCodeState(
      email: email ?? this.email,
      emailType: emailType ?? this.emailType,
      codeDigits: codeDigits ?? this.codeDigits,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      resendTimer: resendTimer ?? this.resendTimer,
      newPassword: newPassword ?? this.newPassword,
      verifyPassword: verifyPassword ?? this.verifyPassword,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      password: password ?? this.password,
    );
  }

  String get fullCode => codeDigits.join();

  bool get isCodeComplete => codeDigits.every((d) => d.isNotEmpty);

  @override
  List<Object?> get props => [
    email,
    emailType,
    codeDigits,
    isLoading,
    isSuccess,
    error,
    resendTimer,
    newPassword,
    verifyPassword,
    username,
    displayName,
    password,
  ];
}

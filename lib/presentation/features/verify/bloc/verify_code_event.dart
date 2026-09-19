part of 'verify_code_bloc.dart';

abstract class VerifyCodeEvent extends Equatable {
  const VerifyCodeEvent();

  @override
  List<Object?> get props => [];
}

class VerifyCodeInit extends VerifyCodeEvent {
  final String email;
  final EmailType emailType;
  final String? newPassword;
  final String? verifyPassword;
  final String? username;
  final String? displayName;
  final String? password;

  const VerifyCodeInit({
    required this.email,
    required this.emailType,
    this.newPassword,
    this.verifyPassword,
    this.username,
    this.displayName,
    this.password,
  });

  @override
  List<Object?> get props => [
    email,
    emailType,
    newPassword,
    verifyPassword,
    username,
    displayName,
    password,
  ];
}

class VerifyCodeDigitChanged extends VerifyCodeEvent {
  final int index;
  final String digit;

  const VerifyCodeDigitChanged(this.index, this.digit);

  @override
  List<Object?> get props => [index, digit];
}

class VerifyCodePasted extends VerifyCodeEvent {
  final String code;

  const VerifyCodePasted(this.code);

  @override
  List<Object?> get props => [code];
}

class VerifyCodePressed extends VerifyCodeEvent {}

class ResendCodePressed extends VerifyCodeEvent {
  final String email;
  final EmailType emailType;
  final String? username;
  final String? password;

  const ResendCodePressed(
    this.email,
    this.emailType,
    this.username,
    this.password,
  );

  @override
  List<Object?> get props => [email, emailType, username, password];
}

class TimerTick extends VerifyCodeEvent {}

class VerifyCodeReset extends VerifyCodeEvent {}

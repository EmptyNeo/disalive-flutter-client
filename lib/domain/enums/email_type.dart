// lib/domain/enum/email_type.dart

enum EmailType {
  reset('reset'),
  confirmChangeEmail('confirm-change-email'),
  confirmRegister('confirm');

  final String value;

  const EmailType(this.value);

  static EmailType fromString(String? value) {
    return EmailType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EmailType.confirmRegister,
    );
  }
}

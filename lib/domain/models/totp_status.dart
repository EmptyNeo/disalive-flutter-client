class TotpStatus {
  const TotpStatus({required this.enabled, this.secret, this.qrUrl});

  final bool enabled;
  final String? secret;
  final String? qrUrl;

  factory TotpStatus.fromMap(Map<String, dynamic> map) => TotpStatus(
    enabled: map['enabled'] == true,
    secret: map['secret'] as String?,
    qrUrl: map['qrUrl'] as String?,
  );
}

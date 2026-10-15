import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/models/invite_data.dart';

final RegExp _inviteUrlPattern = RegExp(
  '${RegExp.escape(Domain.imageDomain)}invite/([a-zA-Z0-9]+)',
);

String? inviteCodeFromText(String? text) =>
    text == null ? null : _inviteUrlPattern.firstMatch(text)?.group(1);

enum InvalidInviteReason { revoked, expired, maxed }

InvalidInviteReason? invalidInviteReason(InviteData invite, DateTime now) {
  if (invite.isRevoked) return InvalidInviteReason.revoked;
  final expiresAt = _parseExpiry(invite.expiresAt);
  if (expiresAt != null && !expiresAt.isAfter(now)) {
    return InvalidInviteReason.expired;
  }
  final limit = invite.maxInvite ?? 0;
  if (limit > 0 && (invite.currentCountInvite ?? 0) >= limit) {
    return InvalidInviteReason.maxed;
  }
  return null;
}

DateTime? _parseExpiry(String? value) {
  if (value == null || value.isEmpty) return null;
  final timestamp = int.tryParse(value);
  if (timestamp != null) {
    if (timestamp <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      timestamp < 100000000000 ? timestamp * 1000 : timestamp,
      isUtc: true,
    );
  }
  return DateTime.tryParse(value);
}

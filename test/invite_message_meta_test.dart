import 'package:disalive/domain/models/invite_data.dart';
import 'package:disalive/presentation/features/message/widgets/invite_message_meta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts the invite code only from a matching link', () {
    expect(
      inviteCodeFromText('Join us: https://disalive.ru/invite/Ab12 now'),
      'Ab12',
    );
    expect(inviteCodeFromText('https://other.ru/invite/Ab12'), isNull);
    expect(inviteCodeFromText('https://disalive.ru/invite/'), isNull);
    expect(inviteCodeFromText(null), isNull);
  });

  test('resolves invalid invite reasons from server data', () {
    final now = DateTime.utc(2026, 10, 14);
    expect(
      invalidInviteReason(
        const InviteData(revoked: true, expiresAt: '2020-01-01'),
        now,
      ),
      InvalidInviteReason.revoked,
    );
    expect(
      invalidInviteReason(
        const InviteData(expiresAt: '2020-01-01T00:00:00Z'),
        now,
      ),
      InvalidInviteReason.expired,
    );
    expect(
      invalidInviteReason(
        const InviteData(maxInvite: 5, currentCountInvite: 5),
        now,
      ),
      InvalidInviteReason.maxed,
    );
    expect(
      invalidInviteReason(const InviteData(expiresAt: '0', maxInvite: 0), now),
      isNull,
    );
  });

  test('parses image path and creator data from a message invite', () {
    final invite = InviteData.fromMap({
      'pathImage': '/server/avatar.png',
      'user': {'displayName': 'Анна'},
    });
    expect(invite.pathAvatar, '/server/avatar.png');
    expect(invite.user?.displayName, 'Анна');
  });
}

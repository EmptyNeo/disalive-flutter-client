import 'package:disalive/presentation/features/invites/invite_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('срок действия передаётся как длительность в секундах', () {
    expect(InviteLifetime.values.map((lifetime) => lifetime.durationSeconds), [
      null,
      1800,
      3600,
      21600,
      43200,
      86400,
      604800,
      2592000,
    ]);
  });

  test('лимиты использований совпадают с параметром maxUsers', () {
    expect(InviteUsageLimit.values.map((limit) => limit.value), [
      0,
      1,
      5,
      10,
      25,
      100,
    ]);
    expect(
      InviteLifetime.forever.validityText,
      'Ваша ссылка-приглашение будет действовать бессрочно.',
    );
  });
}

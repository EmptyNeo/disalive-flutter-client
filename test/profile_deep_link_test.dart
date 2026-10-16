import 'package:disalive/domain/services/profile_deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile deep link contains one encoded username', () {
    final link = ProfileDeepLink.forUsername('alex.smith');
    expect(link.toString(), 'disalive://profiles/alex.smith');
    expect(ProfileDeepLink.usernameFrom(link), 'alex.smith');
  });

  test('rejects unrelated or incomplete links', () {
    expect(
      ProfileDeepLink.usernameFrom(
        Uri.parse('https://disalive.ru/app/#profiles/alex'),
      ),
      isNull,
    );
    expect(
      ProfileDeepLink.usernameFrom(Uri.parse('disalive://profiles/')),
      isNull,
    );
    expect(
      ProfileDeepLink.usernameFrom(Uri.parse('disalive://profiles/alex/extra')),
      isNull,
    );
    expect(
      ProfileDeepLink.usernameFrom(Uri.parse('disalive://invites/alex')),
      isNull,
    );
  });
}

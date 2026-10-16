import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/profile/widgets/direct_profile_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = UserModel(username: 'alex', displayName: 'Alex');

  testWidgets('profile actions render only when supplied', (tester) async {
    Future<void> pumpProfile({Widget? actions}) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
            width: 400,
            height: 800,
            child: DirectProfileContent(
              user: user,
              isSoloChat: false,
              actions: actions,
            ),
          ),
        ),
      );
    }

    await pumpProfile();
    expect(find.text('Действие профиля'), findsNothing);

    await pumpProfile(actions: const Text('Действие профиля'));
    expect(find.text('Действие профиля'), findsOneWidget);
  });
}

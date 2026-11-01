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

  testWidgets('long profile display name stays within a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const CupertinoApp(
        home: SizedBox(
          width: 320,
          height: 800,
          child: DirectProfileContent(
            user: UserModel(
              username: 'alex',
              displayName:
                  'Очень длинное отображаемое имя, которое раньше выходило за правую границу экрана',
            ),
            isSoloChat: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final name = tester.widget<Text>(find.textContaining('Очень длинное'));
    expect(name.maxLines, 2);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}

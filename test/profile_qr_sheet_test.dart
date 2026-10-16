import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_qr_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('profile QR contains the user link and can copy it', (
    tester,
  ) async {
    const user = UserModel(username: 'alex', displayName: 'Alex');
    const link = 'https://disalive.ru/app/#profiles/alex';
    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => ProfileQrSheet.show(context, user),
            child: const Text('QR'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('QR'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text(link), findsOneWidget);
    expect(
      tester.getSize(find.byType(CupertinoPopupSurface)).width,
      MediaQuery.sizeOf(
        tester.element(find.byType(CupertinoPopupSurface)),
      ).width,
    );

    await tester.tap(find.text('Скопировать ссылку'));
    await tester.pump();

    expect(copied, link);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });
}

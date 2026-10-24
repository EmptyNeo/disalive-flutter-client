import 'package:disalive/domain/models/message.dart';
import 'package:disalive/presentation/features/message/message_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('forwarded message shows original and accompanying text', (
    tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: MessageItem(
            message: const Message(
              id: 2,
              text: 'Мой комментарий к пересылке',
              forwardMessage: Message(id: 1, text: 'Исходный текст'),
            ),
            isMine: true,
            isRead: false,
            showTime: false,
            onStickerTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Исходный текст'), findsOneWidget);
    expect(find.text('Мой комментарий к пересылке'), findsOneWidget);
  });
}

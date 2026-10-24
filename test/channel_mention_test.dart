import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/presentation/features/chat/channel_mention.dart';
import 'package:disalive/presentation/features/message/widgets/message_link_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('channel link renders without ID and passes its ID on tap', (
    tester,
  ) async {
    int? openedChatId;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: MessageLinkText(
            text: 'Смотрите #общий-чат:123',
            style: const TextStyle(),
            onChannelTap: (id) => openedChatId = id,
          ),
        ),
      ),
    );
    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(MessageLinkText),
        matching: find.byType(RichText),
      ),
    );
    final spans = ((richText.text as TextSpan).children!.single as TextSpan)
        .children!;
    final link = spans.whereType<TextSpan>().firstWhere(
      (span) => span.text == '#общий-чат',
    );
    (link.recognizer as TapGestureRecognizer).onTap!();
    expect(openedChatId, 123);
  });

  test('finds channel links with Cyrillic names and numeric chat IDs', () {
    final mentions = ChannelMention.findAll(
      'Смотрите #общий-чат:123 и #голосовой:456, но не #канал:abc.',
    ).toList();
    expect(mentions.map((mention) => mention.chatId), [123, 456]);
    expect(mentions.map((mention) => mention.name), ['общий-чат', 'голосовой']);
  });

  test('detects the active query and inserts a stable channel link', () {
    const value = TextEditingValue(
      text: 'Привет #об',
      selection: TextSelection.collapsed(offset: 10),
    );
    final query = ChannelMention.queryAtCaret(value);
    expect(query?.text, 'об');

    final inserted = ChannelMention.insert(
      value,
      query!,
      const ChannelServer(chatId: 73, chatName: 'Общий чат'),
    );
    expect(inserted.text, 'Привет #Общий-чат:73 ');
    expect(inserted.selection.baseOffset, inserted.text.length);
    expect(ChannelMention.queryAtCaret(inserted), isNull);
  });

  test('does not open suggestions inside a word or an existing link', () {
    expect(
      ChannelMention.queryAtCaret(
        const TextEditingValue(
          text: 'test#ка',
          selection: TextSelection.collapsed(offset: 7),
        ),
      ),
      isNull,
    );
    expect(
      ChannelMention.queryAtCaret(
        const TextEditingValue(
          text: '#канал:42',
          selection: TextSelection.collapsed(offset: 9),
        ),
      ),
      isNull,
    );
  });
}

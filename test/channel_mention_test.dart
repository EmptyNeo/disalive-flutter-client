import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/services/emojis_handler.dart';
import 'package:disalive/presentation/features/chat/channel_mention.dart';
import 'package:disalive/presentation/features/message/widgets/message_link_text.dart';
import 'package:disalive/presentation/widgets/emoji_token.dart';
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
    final spans =
        ((richText.text as TextSpan).children!.single as TextSpan).children!;
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

  test('keeps custom emoji codes inside channel links', () {
    final mentions = ChannelMention.findAll(
      'Откройте #[people:0]общий[custom_emoji:12]:73 и #чат😀:74',
    ).toList();
    expect(mentions.map((mention) => mention.chatId), [73, 74]);
    expect(mentions.map((mention) => mention.name), [
      '[people:0]общий[custom_emoji:12]',
      'чат😀',
    ]);
  });

  test('finds channel links with spaces next to emoji tokens', () {
    final mentions = ChannelMention.findAll(
      '#└── [server_s:8] баг-репорты:626',
    ).toList();
    expect(mentions.map((mention) => mention.chatId), [626]);
    expect(mentions.first.name, '└── [server_s:8] баг-репорты');
  });

  testWidgets('exact channel link with server emoji stays tappable', (
    tester,
  ) async {
    int? openedChatId;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: MessageLinkText(
            text: '#└── [server_s:8] баг-репорты:626',
            style: const TextStyle(),
            onChannelTap: (id) => openedChatId = id,
          ),
        ),
      ),
    );
    final emojiLink = find.byWidgetPredicate(
      (widget) => widget is GestureDetector && widget.child is EmojiToken,
    );
    expect(emojiLink, findsOneWidget);
    await tester.tap(emojiLink);
    expect(openedChatId, 626);
  });

  testWidgets('channel link with custom emoji remains tappable', (
    tester,
  ) async {
    int? openedChatId;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: MessageLinkText(
            text: 'Смотрите #[people:0]общий:73',
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
    final spans =
        ((richText.text as TextSpan).children!.single as TextSpan).children!;
    final emoji = spans.whereType<TextSpan>().firstWhere(
      (span) => span.text == '[people:0]',
    );
    final channelName = spans.whereType<TextSpan>().firstWhere(
      (span) => span.text == 'общий',
    );
    (emoji.recognizer as TapGestureRecognizer).onTap!();
    expect(openedChatId, 73);
    openedChatId = null;
    (channelName.recognizer as TapGestureRecognizer).onTap!();
    expect(openedChatId, 73);
  });

  testWidgets('rendered emoji inside channel link opens the channel', (
    tester,
  ) async {
    await tester.runAsync(() => EmojisHandler.instance.initialize());
    int? openedChatId;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: MessageLinkText(
            text: 'Смотрите #[people:0] Общий чат:73',
            style: const TextStyle(),
            onChannelTap: (id) => openedChatId = id,
          ),
        ),
      ),
    );
    final emojiLink = find.byWidgetPredicate(
      (widget) =>
          widget is GestureDetector &&
          widget.child?.runtimeType.toString() == 'EmojiWidget',
    );
    expect(emojiLink, findsOneWidget);
    await tester.tap(emojiLink);
    expect(openedChatId, 73);
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

  test('inserts the custom emoji code without changing its colon', () {
    const value = TextEditingValue(
      text: '#об',
      selection: TextSelection.collapsed(offset: 3),
    );
    final inserted = ChannelMention.insert(
      value,
      ChannelMention.queryAtCaret(value)!,
      const ChannelServer(chatId: 73, chatName: '[people:0] Общий чат'),
    );
    expect(inserted.text, '#[people:0]-Общий-чат:73 ');
    expect(ChannelMention.findAll(inserted.text).single.chatId, 73);
    expect(
      ChannelMention.findAll(inserted.text).single.name,
      '[people:0]-Общий-чат',
    );
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

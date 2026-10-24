import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/features/chat/user_mention.dart';
import 'package:disalive/presentation/features/message/widgets/message_link_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finds usernames but skips email addresses', () {
    final mentions = UserMention.findAll(
      'Привет @neo_test и @Иван-1. Пиши на mail@example.com',
    ).toList();
    expect(mentions.map((mention) => mention.username), ['neo_test', 'Иван-1']);
  });

  test('detects @ query at caret and inserts selected username', () {
    const value = TextEditingValue(
      text: 'Привет @ne, как дела?',
      selection: TextSelection.collapsed(offset: 10),
    );
    final query = UserMention.queryAtCaret(value);
    expect(query?.text, 'ne');
    final inserted = UserMention.insert(
      value,
      query!,
      const UserModel(id: 2, username: 'neo'),
    );
    expect(inserted.text, 'Привет @neo , как дела?');
    expect(inserted.selection.baseOffset, 12);
    expect(UserMention.queryAtCaret(inserted), isNull);
  });

  test('does not show suggestions in an email or ordinary word', () {
    expect(
      UserMention.queryAtCaret(
        const TextEditingValue(
          text: 'mail@example',
          selection: TextSelection.collapsed(offset: 12),
        ),
      ),
      isNull,
    );
    expect(
      UserMention.queryAtCaret(
        const TextEditingValue(
          text: 'test@neo',
          selection: TextSelection.collapsed(offset: 8),
        ),
      ),
      isNull,
    );
  });

  testWidgets('message mention has brand background and rounded corners', (
    tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: MessageLinkText(
            text: 'Привет @neo',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
    final mention = find.byKey(const ValueKey('user_mention_neo_7'));
    expect(mention, findsOneWidget);
    expect(find.text('@neo'), findsOneWidget);
    final container = tester.widget<Container>(
      find.descendant(of: mention, matching: find.byType(Container)).first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.blurple);
    expect(decoration.borderRadius, BorderRadius.circular(5));
  });
}

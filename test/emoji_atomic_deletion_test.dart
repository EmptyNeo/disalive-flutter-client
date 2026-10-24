import 'package:disalive/presentation/widgets/emoji_text_editing_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = EmojiAtomicDeletionFormatter();

  test('keyboard backspace removes emoji token and following space', () {
    const before = TextEditingValue(
      text: 'Привет [people:12] мир',
      selection: TextSelection.collapsed(offset: 19),
    );
    const afterKeyboard = TextEditingValue(
      text: 'Привет [people:12]мир',
      selection: TextSelection.collapsed(offset: 18),
    );

    final result = formatter.formatEditUpdate(before, afterKeyboard);
    expect(result.text, 'Привет мир');
    expect(result.selection.baseOffset, 7);
    expect(formatter.deleteBackward(before), result);
  });

  test('deleting a character inside an emoji removes the whole token', () {
    const before = TextEditingValue(
      text: 'а[people:12]б',
      selection: TextSelection.collapsed(offset: 12),
    );
    const afterKeyboard = TextEditingValue(
      text: 'а[people:12б',
      selection: TextSelection.collapsed(offset: 11),
    );
    final result = formatter.formatEditUpdate(before, afterKeyboard);
    expect(result.text, 'аб');
    expect(result.selection.baseOffset, 1);
  });

  test('ordinary characters retain keyboard deletion behavior', () {
    const before = TextEditingValue(
      text: 'Привет',
      selection: TextSelection.collapsed(offset: 6),
    );
    const afterKeyboard = TextEditingValue(
      text: 'Приве',
      selection: TextSelection.collapsed(offset: 5),
    );
    expect(formatter.formatEditUpdate(before, afterKeyboard), afterKeyboard);
    expect(formatter.deleteBackward(before), afterKeyboard);
  });
}

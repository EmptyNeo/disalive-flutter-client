import 'package:disalive/presentation/utils/ui/emoji_text_parser.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:disalive/app/theme/app_theme.dart';

class EmojiTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Если текст пустой, возвращаем стандартный спан
    if (text.isEmpty) {
      return TextSpan(style: style);
    }

    final spans = EmojiTextParser.parse(
      text,
      baseTextStyle:
          style ?? AppText.mediumTextStyle.copyWith(color: AppColors.white),
      emojiSize: 18,
    );

    return TextSpan(style: style, children: spans);
  }
}

/// Удаляет пользовательский эмодзи как один символ при вводе с клавиатуры.
class EmojiAtomicDeletionFormatter extends TextInputFormatter {
  const EmojiAtomicDeletionFormatter();

  static final RegExp _token = RegExp(r'\[[a-zA-Z0-9_]+:\d+\]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;
    if (newText.length >= oldText.length) return newValue;

    var prefix = 0;
    while (prefix < newText.length &&
        prefix < oldText.length &&
        oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }

    var suffix = 0;
    while (suffix < oldText.length - prefix &&
        suffix < newText.length - prefix &&
        oldText.codeUnitAt(oldText.length - suffix - 1) ==
            newText.codeUnitAt(newText.length - suffix - 1)) {
      suffix++;
    }

    final removedEnd = oldText.length - suffix;
    var expandedStart = prefix;
    var expandedEnd = removedEnd;
    var touchesEmoji = false;
    for (final match in _token.allMatches(oldText)) {
      final tokenEnd = match.end < oldText.length && oldText[match.end] == ' '
          ? match.end + 1
          : match.end;
      if (prefix < tokenEnd && removedEnd > match.start) {
        touchesEmoji = true;
        if (match.start < expandedStart) expandedStart = match.start;
        if (tokenEnd > expandedEnd) expandedEnd = tokenEnd;
      }
    }
    if (!touchesEmoji) return newValue;

    final replacement = newText.substring(prefix, newText.length - suffix);
    return TextEditingValue(
      text: oldText.replaceRange(expandedStart, expandedEnd, replacement),
      selection: TextSelection.collapsed(
        offset: expandedStart + replacement.length,
      ),
    );
  }

  TextEditingValue deleteBackward(TextEditingValue value) {
    final selection = value.selection;
    if (!selection.isValid || selection.start < 0) return value;
    if (selection.isCollapsed && selection.start == 0) return value;
    final start = selection.isCollapsed ? selection.start - 1 : selection.start;
    final candidate = TextEditingValue(
      text: value.text.replaceRange(start, selection.end, ''),
      selection: TextSelection.collapsed(offset: start),
    );
    return formatEditUpdate(value, candidate);
  }
}

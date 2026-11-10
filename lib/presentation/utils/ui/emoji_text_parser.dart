import 'package:flutter/material.dart';
import 'package:disalive/domain/services/emojis_handler.dart';
import 'package:disalive/presentation/widgets/emoji_widget.dart'; // Проверь путь к твоему EmojiWidget
import 'package:disalive/presentation/widgets/emoji_token.dart';

class EmojiTextParser {
  static List<InlineSpan> parse(
    String text, {
    TextStyle? baseTextStyle,
    double emojiSize = 20,
    bool animateEmoji = true,
  }) {
    final List<InlineSpan> spans = [];
    final regex = RegExp(r'\[([a-zA-Z0-9_]+):(\d+)\]');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: baseTextStyle,
          ),
        );
      }

      final category = match.group(1) ?? '';
      final id = match.group(2) ?? '';

      // Синхронный поиск (работает мгновенно, так как это Map lookup)
      final emojiDef = EmojisHandler.instance.getEmojiById(category, id);
      final sheetData = EmojisHandler.instance.getSheetDataByCategory(category);

      if (category.startsWith('server_')) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: EmojiToken(
              category: category,
              id: id,
              token: match.group(0)!,
              size: emojiSize,
              style: baseTextStyle,
              animate: animateEmoji,
            ),
          ),
        );
      } else if (emojiDef != null && sheetData != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            // Выравнивание по центру строки
            child: EmojiWidget(
              emoji: emojiDef,
              sheetData: sheetData,
              size: emojiSize,
              animate: animateEmoji,
            ),
          ),
        );
      } else {
        // Если эмодзи не найден, показываем исходный текст
        spans.add(TextSpan(text: match.group(0), style: baseTextStyle));
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(text: text.substring(lastMatchEnd), style: baseTextStyle),
      );
    }

    return spans;
  }
}

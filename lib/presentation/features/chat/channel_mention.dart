import 'package:disalive/domain/models/channel_server.dart';
import 'package:flutter/services.dart';

/// The ID is kept in the message so renaming a channel does not break the link.
class ChannelMention {
  const ChannelMention(this.start, this.end, this.name, this.chatId);

  final int start;
  final int end;
  final String name;
  final int chatId;

  static final RegExp _pattern = RegExp(r'#([^\s:#]+):([1-9]\d*)');

  static Iterable<ChannelMention> findAll(String text) sync* {
    for (final match in _pattern.allMatches(text)) {
      if (match.start > 0 &&
          !RegExp(r'\s').hasMatch(text[match.start - 1]) &&
          !'([{'.contains(text[match.start - 1])) {
        continue;
      }
      final id = int.tryParse(match.group(2)!);
      if (id != null) {
        yield ChannelMention(match.start, match.end, match.group(1)!, id);
      }
    }
  }

  static ChannelMentionQuery? queryAtCaret(TextEditingValue value) {
    final selection = value.selection;
    if (!selection.isValid || !selection.isCollapsed) return null;
    final caret = selection.extentOffset;
    if (caret < 1 || caret > value.text.length) return null;
    final start = value.text.lastIndexOf('#', caret - 1);
    if (start < 0 ||
        (start > 0 && !RegExp(r'\s').hasMatch(value.text[start - 1]))) {
      return null;
    }
    final query = value.text.substring(start + 1, caret);
    if (RegExp(r'[\s:#]').hasMatch(query)) return null;
    return ChannelMentionQuery(start, caret, query);
  }

  static TextEditingValue insert(
    TextEditingValue value,
    ChannelMentionQuery query,
    ChannelServer channel,
  ) {
    final chatId = channel.chatId;
    if (chatId == null) return value;
    final name = (channel.chatName ?? 'Канал').trim().replaceAll(
      RegExp(r'[\s:#]+'),
      '-',
    );
    final suffix = value.text.substring(query.end);
    final mention =
        '#$name:$chatId${suffix.isEmpty || !RegExp(r'\s').hasMatch(suffix[0]) ? ' ' : ''}';
    final text = value.text.replaceRange(query.start, query.end, mention);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: query.start + mention.length),
    );
  }
}

class ChannelMentionQuery {
  const ChannelMentionQuery(this.start, this.end, this.text);

  final int start;
  final int end;
  final String text;
}

import 'package:disalive/domain/models/user.dart';
import 'package:flutter/services.dart';

class UserMention {
  const UserMention(this.start, this.end, this.username);

  final int start;
  final int end;
  final String username;

  static final RegExp _pattern = RegExp(
    r'(?<![\p{L}\p{N}_@])@([\p{L}\p{N}_]+(?:[.-][\p{L}\p{N}_]+)*)',
    unicode: true,
  );

  static Iterable<UserMention> findAll(String text) sync* {
    for (final match in _pattern.allMatches(text)) {
      yield UserMention(match.start, match.end, match.group(1)!);
    }
  }

  static UserMentionQuery? queryAtCaret(TextEditingValue value) {
    final selection = value.selection;
    if (!selection.isValid || !selection.isCollapsed) return null;
    final caret = selection.extentOffset;
    if (caret < 1 || caret > value.text.length) return null;
    final start = value.text.lastIndexOf('@', caret - 1);
    if (start < 0) return null;
    if (start > 0 &&
        RegExp(
          r'[\p{L}\p{N}_@]',
          unicode: true,
        ).hasMatch(value.text[start - 1])) {
      return null;
    }
    final query = value.text.substring(start + 1, caret);
    if (!RegExp(r'^[\p{L}\p{N}_.-]*$', unicode: true).hasMatch(query)) {
      return null;
    }
    return UserMentionQuery(start, caret, query);
  }

  static TextEditingValue insert(
    TextEditingValue value,
    UserMentionQuery query,
    UserModel user,
  ) {
    final username = user.username;
    if (username == null || username.isEmpty) return value;
    final suffix = value.text.substring(query.end);
    final mention =
        '@$username${suffix.isEmpty || !RegExp(r'\s').hasMatch(suffix[0]) ? ' ' : ''}';
    return TextEditingValue(
      text: value.text.replaceRange(query.start, query.end, mention),
      selection: TextSelection.collapsed(offset: query.start + mention.length),
    );
  }
}

class UserMentionQuery {
  const UserMentionQuery(this.start, this.end, this.text);

  final int start;
  final int end;
  final String text;
}

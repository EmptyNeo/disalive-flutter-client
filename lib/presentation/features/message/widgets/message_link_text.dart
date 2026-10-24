import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/features/chat/channel_mention.dart';
import 'package:disalive/presentation/features/chat/user_mention.dart';
import 'package:disalive/presentation/features/profile/user_profile_screen.dart';
import 'package:disalive/presentation/utils/ui/emoji_text_parser.dart';
import 'package:disalive/presentation/widgets/link_opener.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

/// Текст сообщения с пользовательскими эмодзи и нажимаемыми ссылками.
class MessageLinkText extends StatefulWidget {
  const MessageLinkText({
    super.key,
    required this.text,
    required this.style,
    this.reserveWidth,
    this.onChannelTap,
  });

  final String text;
  final TextStyle style;
  final double? reserveWidth;
  final ValueChanged<int>? onChannelTap;

  @override
  State<MessageLinkText> createState() => _MessageLinkTextState();
}

class _MessageLinkTextState extends State<MessageLinkText> {
  static final RegExp _urlPattern = RegExp(
    r'(?:https?://|www\.)[^\s<>"\x27]+|(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(?:[/?#][^\s<>"\x27]*)?',
    caseSensitive: false,
  );
  static final RegExp _trailingPunctuation = RegExp(r'[.,!?;:)\]]+$');

  final List<TapGestureRecognizer> _recognizers = [];
  late List<InlineSpan> _spans;

  @override
  void initState() {
    super.initState();
    _rebuildSpans();
  }

  @override
  void didUpdateWidget(covariant MessageLinkText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.onChannelTap != widget.onChannelTap) {
      _rebuildSpans();
    }
  }

  void _rebuildSpans() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    final spans = <InlineSpan>[];
    final matches =
        <
          ({
            int start,
            int end,
            String text,
            String? url,
            int? channelId,
            String? username,
          })
        >[];
    if (widget.onChannelTap != null) {
      for (final mention in ChannelMention.findAll(widget.text)) {
        matches.add((
          start: mention.start,
          end: mention.end,
          text: '#${mention.name}',
          url: null,
          channelId: mention.chatId,
          username: null,
        ));
      }
    }
    for (final mention in UserMention.findAll(widget.text)) {
      matches.add((
        start: mention.start,
        end: mention.end,
        text: '@${mention.username}',
        url: null,
        channelId: null,
        username: mention.username,
      ));
    }
    for (final match in _urlPattern.allMatches(widget.text)) {
      if (match.start > 0 &&
          RegExp(r'[a-zA-Z0-9_@/.-]').hasMatch(widget.text[match.start - 1])) {
        continue;
      }
      final candidate = match.group(0)!;
      final urlText = candidate.replaceFirst(_trailingPunctuation, '');
      if (urlText.isEmpty) continue;
      final target =
          urlText.startsWith(RegExp(r'https?://', caseSensitive: false))
          ? urlText
          : 'https://$urlText';
      final uri = Uri.tryParse(target);
      if (uri == null || uri.host.isEmpty) continue;
      matches.add((
        start: match.start,
        end: match.start + urlText.length,
        text: urlText,
        url: target,
        channelId: null,
        username: null,
      ));
    }
    matches.sort((a, b) => a.start.compareTo(b.start));
    var cursor = 0;
    for (final match in matches) {
      if (match.start < cursor) continue;
      if (match.start > cursor) {
        spans.addAll(
          EmojiTextParser.parse(
            widget.text.substring(cursor, match.start),
            baseTextStyle: widget.style,
            emojiSize: 20,
          ),
        );
      }
      if (match.username != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              key: ValueKey('user_mention_${match.username}_${match.start}'),
              onTap: () =>
                  UserProfileScreen.open(context, username: match.username!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.blurple,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: AppColors.onBlurple.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  match.text,
                  style: widget.style.copyWith(color: AppColors.onBlurple),
                ),
              ),
            ),
          ),
        );
      } else {
        final recognizer = TapGestureRecognizer()
          ..onTap = match.channelId != null
              ? () => widget.onChannelTap?.call(match.channelId!)
              : () => LinkOpener.confirmAndOpen(context, match.url!);
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: match.text,
            style: widget.style.copyWith(
              color: AppColors.linkBlue,
              decoration: TextDecoration.underline,
            ),
            recognizer: recognizer,
          ),
        );
      }
      cursor = match.end;
    }
    if (cursor < widget.text.length) {
      spans.addAll(
        EmojiTextParser.parse(
          widget.text.substring(cursor),
          baseTextStyle: widget.style,
          emojiSize: 20,
        ),
      );
    }
    _spans = spans;
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        ..._spans,
        if (widget.reserveWidth != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(width: widget.reserveWidth),
          ),
      ],
    ),
    textWidthBasis: TextWidthBasis.longestLine,
  );
}

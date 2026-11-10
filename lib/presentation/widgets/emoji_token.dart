import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/repositories/server_emoji_pack_repository.dart';
import 'package:disalive/domain/services/emojis_handler.dart';
import 'package:disalive/presentation/widgets/emoji_widget.dart';
import 'package:flutter/widgets.dart';

/// Displays a token even when its server emoji pack is not installed locally.
class EmojiToken extends StatefulWidget {
  const EmojiToken({
    super.key,
    required this.category,
    required this.id,
    required this.token,
    required this.size,
    this.style,
    this.animate = true,
  });

  final String category;
  final String id;
  final String token;
  final double size;
  final TextStyle? style;
  final bool animate;

  @override
  State<EmojiToken> createState() => _EmojiTokenState();
}

class _EmojiTokenState extends State<EmojiToken> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant EmojiToken oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category || oldWidget.id != widget.id) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final category = widget.category;
    final id = widget.id;
    try {
      await EmojisHandler.instance.ensureServerCategory(
        category,
        id,
        sl<ServerEmojiPackRepository>(),
      );
    } catch (_) {
      // Keep the original token visible if the category cannot be loaded.
    }
    if (mounted && category == widget.category && id == widget.id) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final handler = EmojisHandler.instance;
    final emoji = handler.getEmojiById(widget.category, widget.id);
    final sheet = handler.getSheetDataByCategory(widget.category);
    if (emoji != null && sheet != null) {
      return EmojiWidget(
        emoji: emoji,
        sheetData: sheet,
        size: widget.size,
        animate: widget.animate,
      );
    }
    return Text(widget.token, style: widget.style);
  }
}

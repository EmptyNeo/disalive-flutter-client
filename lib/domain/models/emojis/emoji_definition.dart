import 'package:disalive/domain/models/emojis/emoji_data.dart';

class EmojiDefinition {
  final String id;
  final String? categoryName;
  final List<EmojiFrame> frames;

  EmojiDefinition({required this.id, this.categoryName, required this.frames});

  bool get isAnimated => frames.length > 1;
}

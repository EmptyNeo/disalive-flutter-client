import 'package:disalive/domain/models/emojis/emoji_data.dart';

class EmojiDefinition {
  final String id;
  final String? categoryName;
  final List<EmojiFrame> frames;
  final String? spritePath;
  final String? name;
  final double? frameWidth;
  final double? frameHeight;
  final double? sheetWidth;
  final double? sheetHeight;
  final int? fps;
  final bool loop;

  EmojiDefinition({
    required this.id,
    this.categoryName,
    required this.frames,
    this.spritePath,
    this.name,
    this.frameWidth,
    this.frameHeight,
    this.sheetWidth,
    this.sheetHeight,
    this.fps,
    this.loop = true,
  });

  bool get isAnimated => frames.length > 1;
}

import 'package:disalive/domain/models/emojis/emoji_data.dart';
import 'package:disalive/domain/models/emojis/emoji_definition.dart';

class EmojiSheetData {
  final String sheetName;
  final String assetPath;
  final double frameWidth;
  final double frameHeight;
  final double sheetWidth;
  final double sheetHeight;
  final int? fps;
  final Map<String, EmojiDefinition> emojis;

  EmojiSheetData({
    required this.sheetName,
    required this.assetPath,
    required this.frameWidth,
    required this.frameHeight,
    required this.sheetWidth,
    required this.sheetHeight,
    this.fps,
    required this.emojis,
  });

  factory EmojiSheetData.fromJson(String categoryFromSheet, Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    final Map<String, EmojiDefinition> parsedEmojis = {};

    if (json.containsKey('emojis') && json['emojis'] is Map) {
      // Анимированный формат
      final emojisMap = json['emojis'] as Map<String, dynamic>;
      for (var entry in emojisMap.entries) {
        final data = entry.value as Map<String, dynamic>;
        final framesData = data['frames'] as List<dynamic>;
        parsedEmojis[entry.key] = EmojiDefinition(
          id: entry.key,
          categoryName: categoryFromSheet,
          frames: framesData
              .map((f) => EmojiFrame.fromJson(f as Map<String, dynamic>))
              .toList(),
        );
      }
    } else if (json.containsKey('frames') && json['frames'] is Map) {
      final framesMap = json['frames'] as Map<String, dynamic>;
      for (var entry in framesMap.entries) {
        parsedEmojis[entry.key] = EmojiDefinition(
          id: entry.key,
          categoryName: categoryFromSheet,
          frames: [EmojiFrame.fromJson(entry.value as Map<String, dynamic>)],
        );
      }
    }
    return EmojiSheetData(
      sheetName: meta['name'],
      assetPath: meta['path'] as String,
      frameWidth: (meta['frameSize']['w'] as num).toDouble(),
      frameHeight: (meta['frameSize']['h'] as num).toDouble(),
      sheetWidth: (meta['size']['w'] as num).toDouble(),
      sheetHeight: (meta['size']['h'] as num).toDouble(),
      fps: meta['fps'] as int?,
      emojis: parsedEmojis,
    );
  }
}

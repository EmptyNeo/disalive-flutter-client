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
  final bool loop;
  final Map<String, EmojiDefinition> emojis;
  final bool isNetworkAsset;

  EmojiSheetData({
    required this.sheetName,
    required this.assetPath,
    required this.frameWidth,
    required this.frameHeight,
    required this.sheetWidth,
    required this.sheetHeight,
    this.fps,
    this.loop = true,
    required this.emojis,
    this.isNetworkAsset = false,
  });

  factory EmojiSheetData.fromJson(
    String categoryFromSheet,
    Map<String, dynamic> json, {
    String? sheetNameOverride,
    bool isNetworkAsset = false,
  }) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    final Map<String, EmojiDefinition> parsedEmojis = {};
    String extractedAssetPath = '';

    final frameSize = meta['frameSize'] as Map<String, dynamic>? ?? const {};
    final size = meta['size'] as Map<String, dynamic>?;
    final frameWidth = (frameSize['w'] as num?)?.toDouble() ?? 66;
    final frameHeight = (frameSize['h'] as num?)?.toDouble() ?? 66;
    final sheetWidth = size != null
        ? (size['w'] as num).toDouble()
        : frameWidth;
    final sheetHeight = size != null
        ? (size['h'] as num).toDouble()
        : frameHeight;
    final fps =
        _parseFps(meta['fps'] ?? json['fps']) ??
        (json.containsKey('emojis') ? 12 : null);
    final loop = meta['loop'] != false;

    if (json.containsKey('emojis') && json['emojis'] is Map) {
      // Анимированный формат
      final emojisMap = json['emojis'] as Map<String, dynamic>;
      for (var entry in emojisMap.entries) {
        final data = entry.value as Map<String, dynamic>;
        final framesData = data['frames'] as List<dynamic>;

        // Берем путь из первого эмодзи, так как он общий для листа
        if (extractedAssetPath.isEmpty) {
          extractedAssetPath = data['spritePath'] as String? ?? '';
        }

        parsedEmojis[entry.key] = EmojiDefinition(
          id: entry.key,
          categoryName: categoryFromSheet,
          frames: framesData
              .map((f) => EmojiFrame.fromJson(f as Map<String, dynamic>))
              .toList(),
          spritePath: data['spritePath'] as String?,
          name: data['name'] as String?,
          frameWidth: frameWidth,
          frameHeight: frameHeight,
          sheetWidth: sheetWidth,
          sheetHeight: sheetHeight,
          fps: fps,
          loop: loop,
        );
      }
    } else if (json.containsKey('frames') && json['frames'] is Map) {
      // Статичный формат
      final framesMap = json['frames'] as Map<String, dynamic>;
      for (var entry in framesMap.entries) {
        final frameData = entry.value as Map<String, dynamic>;

        if (extractedAssetPath.isEmpty) {
          extractedAssetPath = frameData['spritePath'] as String? ?? '';
        }

        parsedEmojis[entry.key] = EmojiDefinition(
          id: entry.key,
          categoryName: categoryFromSheet,
          frames: [EmojiFrame.fromJson(frameData)],
          spritePath: frameData['spritePath'] as String?,
          name: frameData['name'] as String?,
          frameWidth: frameWidth,
          frameHeight: frameHeight,
          sheetWidth: sheetWidth,
          sheetHeight: sheetHeight,
          fps: fps,
          loop: loop,
        );
      }
    }

    return EmojiSheetData(
      sheetName:
          sheetNameOverride ?? meta['name'] as String? ?? categoryFromSheet,
      assetPath: extractedAssetPath.isNotEmpty
          ? extractedAssetPath
          : (meta['path'] as String? ?? ''),
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      sheetWidth: sheetWidth,
      sheetHeight: sheetHeight,
      fps: fps,
      loop: loop,
      emojis: parsedEmojis,
      isNetworkAsset: isNetworkAsset,
    );
  }

  static int? _parseFps(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

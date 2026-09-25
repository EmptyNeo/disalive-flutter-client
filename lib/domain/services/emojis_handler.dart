import 'dart:convert';
import 'package:disalive/domain/models/emojis/emoji_definition.dart';
import 'package:disalive/domain/models/emojis/emoji_sheet_data.dart';
import 'package:flutter/services.dart';

class EmojisHandler {
  EmojisHandler._();

  static final EmojisHandler instance = EmojisHandler._();

  final Map<String, EmojiSheetData> _sheets = {};

  Map<String, EmojiSheetData> get sheets => _sheets;

  List<String> get categoryNames {
    return _sheets.values.map((e) => e.sheetName).toList();
  }

  EmojiSheetData? getSheetDataByName(String name) {
    return _sheets.values.firstWhere(
      (sheet) => sheet.sheetName == name,
      orElse: () => throw Exception('Sheet not found: $name'),
    );
  }

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final sheetNames = [
      'sprite_sheet_people',
      'sprite_sheet_nature',
      'sprite_sheet_food_and_drink',
      'sprite_sheet_activity',
      'sprite_sheet_travel_and_places',
      'sprite_sheet_objects',
      'sprite_sheet_symbols',
      'sprite_sheet_flags',
      'sprite_sheet_tornado',
      'sprite_sheet_minecraft',
      'sprite_sheet_minecraft_people',
      'sprite_sheet_anime',
      'sprite_sheet_mad_emoji',
      'sprite_sheet_pepe',
      'sprite_sheet_news',
      //изменил на просто news для совместимости с сайтом, так как на сайте у меня [news:0], а не [news_emoji:0]
    ];

    for (final name in sheetNames) {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/emojis/$name.json',
        );

        final normalizedKey = name
            .replaceAll('sprite_sheet_', '')
            .toLowerCase();

        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final sheetData = EmojiSheetData.fromJson(normalizedKey, json);

        _sheets[normalizedKey] = sheetData;
      } catch (e) {
        print('Ошибка загрузки эмодзи $name: $e');
      }
    }

    _isInitialized = true;
  }

  // 🎯 ПОИСК ПО КАТЕГОРИИ И ID
  EmojiDefinition? getEmojiById(String categoryName, String id) {
    final normalizedCategory = categoryName.toLowerCase().replaceAll(' ', '_');
    return _sheets[normalizedCategory]?.emojis[id];
  }

  EmojiSheetData? getSheetDataByCategory(String categoryName) {
    final normalizedCategory = categoryName.toLowerCase().replaceAll(' ', '_');
    return _sheets[normalizedCategory];
  }
}

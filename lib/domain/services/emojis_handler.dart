import 'dart:convert';
import 'package:disalive/domain/models/emojis/emoji_definition.dart';
import 'package:disalive/domain/models/emojis/emoji_sheet_data.dart';
import 'package:disalive/domain/models/server_emoji_pack.dart';
import 'package:disalive/domain/repositories/server_emoji_pack_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class EmojisHandler {
  EmojisHandler._();

  static final EmojisHandler instance = EmojisHandler._();

  final Map<String, EmojiSheetData> _sheets = {};
  final Map<String, EmojiSheetData> _serverSheets = {};
  final Map<String, ServerEmojiPack> _serverPacks = {};
  bool _serverPacksLoaded = false;
  Future<void>? _serverPackLoadFuture;
  final Map<String, Future<void>> _serverCategoryLoads = {};

  Map<String, EmojiSheetData> get sheets => _sheets;

  List<String> get categoryNames {
    return [
      ..._sheets.values.map((e) => e.sheetName),
      ..._serverPacks.values
          .where((pack) => pack.installed == true)
          .map((pack) => pack.name ?? pack.categoryId ?? '')
          .where((name) => name.isNotEmpty),
    ];
  }

  EmojiSheetData? getSheetDataByName(String name) {
    for (final sheet in _sheets.values) {
      if (sheet.sheetName == name) return sheet;
    }
    for (final entry in _serverPacks.entries) {
      final pack = entry.value;
      if (pack.installed == true &&
          (pack.name == name || pack.categoryId == name)) {
        return _serverSheets[entry.key];
      }
    }
    return null;
  }

  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() {
    if (_isInitialized) return Future<void>.value();
    if (_initializationFuture != null) return _initializationFuture!;
    final future = _initialize();
    _initializationFuture = future;
    return future;
  }

  Future<void> _initialize() async {
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
        debugPrint('Ошибка загрузки эмодзи $name: $e');
      }
    }

    _isInitialized = true;
    _initializationFuture = null;
  }

  /// Loads all emoji packs visible to the current user. Emoji lookups stay
  /// synchronous after this call so message parsing can render server emojis.
  Future<void> loadServerEmojiPacks(
    ServerEmojiPackRepository repository, {
    bool force = false,
  }) {
    if (_serverPackLoadFuture != null && !force) return _serverPackLoadFuture!;
    if (_serverPacksLoaded && !force) return Future<void>.value();
    final future = _loadServerEmojiPacks(repository);
    _serverPackLoadFuture = future;
    return future;
  }

  Future<void> _loadServerEmojiPacks(
    ServerEmojiPackRepository repository,
  ) async {
    try {
      final result = await repository.getPacks();
      result.fold((_) {}, (packs) {
        _serverPacks
          ..clear()
          ..addEntries(
            packs
                .where((pack) => pack.categoryId?.isNotEmpty == true)
                .map((pack) => MapEntry(pack.categoryId!, pack)),
          );
        _serverSheets
          ..clear()
          ..addEntries(
            packs
                .map(
                  (pack) =>
                      MapEntry(pack.categoryId ?? '', _sheetForPack(pack)),
                )
                .where((entry) => entry.key.isNotEmpty && entry.value != null)
                .map((entry) => MapEntry(entry.key, entry.value!)),
          );
        _serverPacksLoaded = true;
      });
    } finally {
      _serverPackLoadFuture = null;
    }
  }

  /// Resolves an emoji from a server pack that the viewer has not installed.
  /// The category endpoint is also used to refresh a pack missing a new emoji.
  Future<void> ensureServerCategory(
    String categoryId,
    String emojiId,
    ServerEmojiPackRepository repository,
  ) async {
    if (!RegExp(r'^server_[a-z]+$').hasMatch(categoryId)) return;
    if (_serverPackLoadFuture != null) await _serverPackLoadFuture;
    if (getEmojiById(categoryId, emojiId) != null) return;

    final future = _serverCategoryLoads.putIfAbsent(categoryId, () async {
      final result = await repository.getPacks(categoryId: categoryId);
      result.fold((_) {}, (packs) {
        for (final pack in packs) {
          if (pack.categoryId != categoryId) continue;
          _serverPacks[categoryId] = pack;
          final sheet = _sheetForPack(pack);
          if (sheet != null) _serverSheets[categoryId] = sheet;
          break;
        }
      });
    });
    try {
      await future;
    } finally {
      if (identical(_serverCategoryLoads[categoryId], future)) {
        _serverCategoryLoads.remove(categoryId);
      }
    }
  }

  /// Updates the cached packs for one server after a management or install
  /// operation, preserving packs loaded for other servers.
  void updateServerEmojiPacksForServer(
    int serverId,
    List<ServerEmojiPack> packs,
  ) {
    final currentCategoryIds = _serverPacks.entries
        .where((entry) => entry.value.serverId == serverId)
        .map((entry) => entry.key)
        .toList();
    for (final categoryId in currentCategoryIds) {
      _serverPacks.remove(categoryId);
      _serverSheets.remove(categoryId);
    }
    for (final pack in packs) {
      final categoryId = pack.categoryId;
      if (categoryId == null || categoryId.isEmpty) continue;
      _serverPacks[categoryId] = pack;
      final sheet = _sheetForPack(pack);
      if (sheet != null) _serverSheets[categoryId] = sheet;
    }
    _serverPacksLoaded = true;
  }

  EmojiSheetData? _sheetForPack(ServerEmojiPack pack) {
    final sheets = pack.jsons;
    if (sheets == null || sheets.isEmpty) return null;
    final categoryId = pack.categoryId ?? 'server_pack';
    final emojis = <String, EmojiDefinition>{};
    EmojiSheetData? baseSheet;
    EmojiSheetData? animatedSheet;
    for (final sheet in sheets) {
      baseSheet ??= sheet;
      if (sheet.emojis.values.any((emoji) => emoji.isAnimated)) {
        animatedSheet ??= sheet;
      }
      emojis.addAll(sheet.emojis);
    }
    final source = baseSheet;
    if (source == null || emojis.isEmpty) return null;
    return EmojiSheetData(
      sheetName: pack.name ?? source.sheetName,
      assetPath: source.assetPath,
      frameWidth: source.frameWidth,
      frameHeight: source.frameHeight,
      sheetWidth: source.sheetWidth,
      sheetHeight: source.sheetHeight,
      fps: animatedSheet?.fps ?? source.fps,
      loop: animatedSheet?.loop ?? source.loop,
      emojis: emojis.map(
        (id, emoji) => MapEntry(
          id,
          EmojiDefinition(
            id: emoji.id,
            categoryName: categoryId,
            frames: emoji.frames,
            spritePath: emoji.spritePath,
            name: emoji.name,
            frameWidth: emoji.frameWidth,
            frameHeight: emoji.frameHeight,
            sheetWidth: emoji.sheetWidth,
            sheetHeight: emoji.sheetHeight,
            fps: emoji.fps,
            loop: emoji.loop,
          ),
        ),
      ),
      isNetworkAsset: true,
    );
  }

  EmojiDefinition? getEmojiById(String categoryName, String id) {
    final normalizedCategory = categoryName.toLowerCase().replaceAll(' ', '_');
    return _sheets[normalizedCategory]?.emojis[id] ??
        _serverSheets[categoryName]?.emojis[id] ??
        _serverSheets[normalizedCategory]?.emojis[id];
  }

  EmojiSheetData? getSheetDataByCategory(String categoryName) {
    final normalizedCategory = categoryName.toLowerCase().replaceAll(' ', '_');
    return _sheets[normalizedCategory] ??
        _serverSheets[categoryName] ??
        _serverSheets[normalizedCategory];
  }

  EmojiDefinition? getEmojiByName(String nameReaction) {
    if (nameReaction.isEmpty) return null;

    final regex = RegExp(r'^\[([a-zA-Z0-9_]+):(\d+)\]$');
    final match = regex.firstMatch(nameReaction);

    if (match != null) {
      final category = match.group(1)!;
      final id = match.group(2)!;

      return getEmojiById(category, id);
    }

    return null;
  }
}

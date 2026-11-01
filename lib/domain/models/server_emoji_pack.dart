import 'package:disalive/domain/models/emojis/emoji_sheet_data.dart';
import 'package:equatable/equatable.dart';

class ServerEmojiPack extends Equatable {
  final int? id;
  final int? serverId;
  final String? name;
  final String? categoryId;
  final bool? installed;
  final List<EmojiSheetData>? jsons; // 🎯 Изменено на List<EmojiSheetData>

  const ServerEmojiPack(
    this.id,
    this.serverId,
    this.name,
    this.categoryId,
    this.installed,
    this.jsons,
  );

  factory ServerEmojiPack.fromMap(Map<String, dynamic> map) {
    List<EmojiSheetData>? parsedJsons;

    if (map['jsons'] is List) {
      final categoryId = map['categoryId'] as String? ?? 'server_pack';
      parsedJsons = (map['jsons'] as List)
          .whereType<Map<String, dynamic>>()
          .map(
            (json) => EmojiSheetData.fromJson(
              categoryId,
              json,
              sheetNameOverride: map['name'] as String?,
              isNetworkAsset: true,
            ),
          )
          .toList();
    }

    return ServerEmojiPack(
      _parseInt(map['id']),
      _parseInt(map['serverId']),
      map['name'] as String?,
      map['categoryId'] as String?,
      _parseBool(map['installed']),
      parsedJsons,
    );
  }

  static int? _parseInt(dynamic value) => value is int
      ? value
      : value is String
      ? int.tryParse(value)
      : null;

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      if (value == '1' || value.toLowerCase() == 'true') return true;
      if (value == '0' || value.toLowerCase() == 'false') return false;
    }
    return null;
  }

  ServerEmojiPack copyWith({
    int? id,
    int? serverId,
    String? name,
    String? categoryId,
    bool? installed,
    List<EmojiSheetData>? jsons,
  }) {
    return ServerEmojiPack(
      id ?? this.id,
      serverId ?? this.serverId,
      name ?? this.name,
      categoryId ?? this.categoryId,
      installed ?? this.installed,
      jsons ?? this.jsons,
    );
  }

  @override
  List<Object?> get props => [id, serverId, name, categoryId, installed, jsons];
}

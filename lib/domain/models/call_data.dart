import 'dart:convert';

import 'package:disalive/presentation/utils/data_parser.dart';

class CallToken {
  const CallToken({
    required this.token,
    required this.userId,
    required this.chatId,
    required this.iceServers,
  });

  final String token;
  final int userId;
  final int chatId;
  final List<CallIceServer> iceServers;

  factory CallToken.fromMap(Map<String, dynamic> map) {
    final rawIceServers = map['iceServers'];
    if (rawIceServers is! List || rawIceServers.isEmpty) {
      throw const FormatException('TURN configuration is missing');
    }
    return CallToken(
      token: map['token'] as String,
      userId: DataParser.parseInt(map['userId'])!,
      chatId: DataParser.parseInt(map['chatId'])!,
      iceServers: rawIceServers
          .map(
            (server) => CallIceServer.fromMap(server as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class CallIceServer {
  const CallIceServer({
    required this.urls,
    required this.username,
    required this.credential,
  });

  final List<String> urls;
  final String username;
  final String credential;

  factory CallIceServer.fromMap(Map<String, dynamic> map) {
    final rawUrls = map['urls'];
    final username = map['username'];
    final credential = map['credential'];
    if (rawUrls is! List ||
        rawUrls.isEmpty ||
        !rawUrls.every((url) => url is String && url.isNotEmpty) ||
        username is! String ||
        username.isEmpty ||
        credential is! String ||
        credential.isEmpty) {
      throw const FormatException('Invalid TURN configuration');
    }
    return CallIceServer(
      urls: List<String>.from(rawUrls),
      username: username,
      credential: credential,
    );
  }
}

class CallBan {
  const CallBan({required this.id, this.expiresAt});

  final int id;
  final String? expiresAt;

  factory CallBan.fromMap(Map<String, dynamic> map) => CallBan(
    id: DataParser.parseInt(map['id'])!,
    expiresAt: map['expiresAt']?.toString(),
  );
}

class CallTrack {
  const CallTrack({
    required this.sid,
    required this.type,
    required this.name,
    required this.source,
    required this.muted,
    required this.mimeType,
  });

  final String sid;
  final int? type;
  final String name;
  final String source;
  final bool muted;
  final String mimeType;

  factory CallTrack.fromMap(Map<String, dynamic> map) => CallTrack(
    sid: map['sid']?.toString() ?? '',
    type: DataParser.parseInt(map['type']),
    name: map['name']?.toString() ?? '',
    source: map['source']?.toString() ?? 'unknown',
    muted: DataParser.parseBool(map['muted']) ?? false,
    mimeType: map['mimeType']?.toString() ?? '',
  );
}

class CallParticipant {
  const CallParticipant({
    required this.identity,
    required this.name,
    required this.metadata,
    required this.tracks,
    this.startedAt,
    this.serverNow,
  });

  final String identity;
  final String name;
  final Map<String, dynamic> metadata;
  final List<CallTrack> tracks;

  /// Время в миллисекундах Unix, как в ответе API.
  final int? startedAt;
  final int? serverNow;

  String get displayName =>
      (metadata['displayName'] ??
              metadata['username'] ??
              (name.isNotEmpty ? name : identity))
          .toString();

  String? get avatarPath =>
      (metadata['pathImage'] ?? metadata['pathAvatar'])?.toString();

  bool get microphoneEnabled =>
      tracks.any((track) => track.source == 'microphone' && !track.muted);

  /// LiveKit не сообщает состояние устройства вывода в списке треков.
  bool? get headphonesEnabled {
    final enabled = DataParser.parseBool(metadata['headphonesEnabled']);
    if (enabled != null) return enabled;
    final deafened = DataParser.parseBool(
      metadata['deafened'] ?? metadata['isDeafened'],
    );
    return deafened == null ? null : !deafened;
  }

  factory CallParticipant.fromMap(Map<String, dynamic> map) {
    final rawMetadata = map['metadata'];
    Map<String, dynamic> metadata = const {};
    if (rawMetadata is Map) {
      metadata = Map<String, dynamic>.from(rawMetadata);
    } else if (rawMetadata is String && rawMetadata.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMetadata);
        if (decoded is Map) metadata = Map<String, dynamic>.from(decoded);
      } on FormatException {
        // LiveKit может вернуть пустую или не-JSON строку metadata.
      }
    }

    return CallParticipant(
      identity: map['identity']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      metadata: metadata,
      tracks: (map['tracks'] as List? ?? const [])
          .map((item) => CallTrack.fromMap(item as Map<String, dynamic>))
          .toList(),
      startedAt: DataParser.parseInt(map['startedAt']),
      serverNow: DataParser.parseInt(map['serverNow']),
    );
  }
}

class CallParticipants {
  const CallParticipants(this.rooms);

  /// Ключ — ID чата/канала в виде строки, как в ответе LiveKit API.
  final Map<String, List<CallParticipant>> rooms;

  List<CallParticipant> forChat(int chatId) => rooms['$chatId'] ?? const [];

  factory CallParticipants.fromMap(Map<String, dynamic> map) {
    final rawRooms = map['rooms'] as Map<String, dynamic>;
    return CallParticipants(
      rawRooms.map(
        (roomId, rawParticipants) => MapEntry(
          roomId,
          (rawParticipants as List)
              .map(
                (item) => CallParticipant.fromMap(item as Map<String, dynamic>),
              )
              .toList(),
        ),
      ),
    );
  }
}

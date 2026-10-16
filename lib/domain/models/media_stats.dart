import 'package:equatable/equatable.dart';

class MediaStats extends Equatable {
  const MediaStats({
    required this.chatId,
    this.photos = 0,
    this.videos = 0,
    this.files = 0,
    this.audio = 0,
    this.links = 0,
    this.mutualChatsCount = 0,
  });

  final int chatId;
  final int photos;
  final int videos;
  final int files;
  final int audio;
  final int links;
  final int mutualChatsCount;

  factory MediaStats.fromMap(int chatId, Map<String, dynamic> map) =>
      MediaStats(
        chatId: chatId,
        photos: _count(map['photos']),
        videos: _count(map['videos']),
        files: _count(map['files']),
        audio: _count(map['audio']),
        links: _count(map['links']),
        mutualChatsCount: _count(map['mutualChatsCount']),
      );

  static int _count(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  List<Object?> get props => [
    chatId,
    photos,
    videos,
    files,
    audio,
    links,
    mutualChatsCount,
  ];
}

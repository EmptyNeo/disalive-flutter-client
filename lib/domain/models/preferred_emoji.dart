import 'package:equatable/equatable.dart';

class PreferredEmoji extends Equatable {
  final int? id;
  final int? fkUser;
  final String? emoji;
  final int? useCount;
  final String? lastUseDatetime;

  const PreferredEmoji({
    this.id,
    this.fkUser,
    this.emoji,
    this.useCount,
    this.lastUseDatetime,
  });

  factory PreferredEmoji.fromMap(Map<String, dynamic> map) {
    return PreferredEmoji(
      id: map['id'],
      fkUser: map['fkUser'],
      emoji: map['emoji'],
      useCount: map['useCount'],
      lastUseDatetime: map['lastUseDatetime'],
    );
  }

  PreferredEmoji copyWith({
    int? id,
    int? fkUser,
    String? emoji,
    int? useCount,
    String? lastUseDatetime,
  }) {
    return PreferredEmoji(
      id: id ?? this.id,
      fkUser: fkUser ?? this.fkUser,
      emoji: emoji ?? this.emoji,
      useCount: useCount ?? this.useCount,
      lastUseDatetime: lastUseDatetime ?? this.lastUseDatetime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (fkUser != null) 'fkUser': fkUser,
      if (emoji != null) 'emoji': emoji,
      if (useCount != null) 'useCount': useCount,
      if (lastUseDatetime != null) 'lastUseDatetime': lastUseDatetime,
    };
  }

  @override
  List<Object?> get props => [id, fkUser, emoji, useCount, lastUseDatetime];
}

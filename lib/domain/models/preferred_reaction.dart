import 'package:equatable/equatable.dart';

class PreferredReaction extends Equatable {
  final int? id;
  final int? fkUser;
  final String? nameReaction;
  final int? useCount;
  final String? lastUseDatetime;

  const PreferredReaction({
    this.id,
    this.fkUser,
    this.nameReaction,
    this.useCount,
    this.lastUseDatetime,
  });

  factory PreferredReaction.fromMap(Map<String, dynamic> map) {
    return PreferredReaction(
      id: map['id'],
      fkUser: map['fkUser'],
      nameReaction: map['nameReaction'],
      useCount: map['useCount'],
      lastUseDatetime: map['lastUseDatetime'],
    );
  }

  PreferredReaction copyWith({
    int? id,
    int? fkUser,
    String? nameReaction,
    int? useCount,
    String? lastUseDatetime,
  }) {
    return PreferredReaction(
      id: id ?? this.id,
      fkUser: fkUser ?? this.fkUser,
      nameReaction: nameReaction ?? this.nameReaction,
      useCount: useCount ?? this.useCount,
      lastUseDatetime: lastUseDatetime ?? this.lastUseDatetime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (fkUser != null) 'fkUser': fkUser,
      if (nameReaction != null) 'nameReaction': nameReaction,
      if (useCount != null) 'useCount': useCount,
      if (lastUseDatetime != null) 'lastUseDatetime': lastUseDatetime,
    };
  }

  @override
  List<Object?> get props => [
    id,
    fkUser,
    nameReaction,
    useCount,
    lastUseDatetime,
  ];
}

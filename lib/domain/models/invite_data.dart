// lib/domain/models/invite_data.dart
import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:equatable/equatable.dart';

class InviteData extends Equatable {
  final int? id;
  final String? name;
  final String? pathAvatar;
  final int? memberCount;
  final int? onlineMemberCount;
  final bool? revoked;
  final String? expiresAt;
  final int? maxInvite;
  final int? currentCountInvite;
  final String? createdAt;

  const InviteData({
    this.id,
    this.name,
    this.pathAvatar,
    this.memberCount,
    this.onlineMemberCount,
    this.revoked,
    this.expiresAt,
    this.maxInvite,
    this.currentCountInvite,
    this.createdAt,
  });

  factory InviteData.fromMap(Map<String, dynamic> map) {
    return InviteData(
      id: map['id'],
      name: map['name'],
      pathAvatar: map['pathAvatar'] ?? map['path_avatar'],
      memberCount: map['memberCount'],
      onlineMemberCount: map['onlineMemberCount'],
      revoked: DataParser.parseBool(map['revoked']),
      expiresAt: map['expiresAt'],
      maxInvite: map['maxInvite'],
      currentCountInvite: map['currentCountInvite'],
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (pathAvatar != null) 'pathAvatar': pathAvatar,
      if (memberCount != null) 'memberCount': memberCount,
      if (onlineMemberCount != null) 'onlineMemberCount': onlineMemberCount,
      if (revoked != null) 'revoked': revoked,
      if (expiresAt != null) 'expiresAt': expiresAt,
      if (maxInvite != null) 'maxInvite': maxInvite,
      if (currentCountInvite != null) 'currentCountInvite': currentCountInvite,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  InviteData copyWith({
    int? id,
    String? name,
    String? pathAvatar,
    int? memberCount,
    int? onlineMemberCount,
    bool? revoked,
    String? expiresAt,
    int? maxInvite,
    int? currentCountInvite,
    String? createdAt,
  }) {
    return InviteData(
      id: id ?? this.id,
      name: name ?? this.name,
      pathAvatar: pathAvatar ?? this.pathAvatar,
      memberCount: memberCount ?? this.memberCount,
      onlineMemberCount: onlineMemberCount ?? this.onlineMemberCount,
      revoked: revoked ?? this.revoked,
      expiresAt: expiresAt ?? this.expiresAt,
      maxInvite: maxInvite ?? this.maxInvite,
      currentCountInvite: currentCountInvite ?? this.currentCountInvite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isRevoked => revoked ?? false;

  bool get hasAvatar => pathAvatar != null && pathAvatar!.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    name,
    pathAvatar,
    memberCount,
    onlineMemberCount,
    revoked,
    expiresAt,
    maxInvite,
    currentCountInvite,
    createdAt,
  ];
}

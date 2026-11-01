import 'package:equatable/equatable.dart';

class EntityModeration extends Equatable {
  final int id;
  final int userId;
  final String? username;
  final String? displayName;
  final String? pathImage;
  final String action;
  final String? expiresAt;
  final String? reason;
  final int? moderatorId;
  final String? createdAt;

  const EntityModeration({
    required this.id,
    required this.userId,
    this.username,
    this.displayName,
    this.pathImage,
    required this.action,
    this.expiresAt,
    this.reason,
    this.moderatorId,
    this.createdAt,
  });

  factory EntityModeration.fromMap(Map<String, dynamic> map) =>
      EntityModeration(
        id: (map['id'] as num?)?.toInt() ?? 0,
        userId: (map['userId'] as num?)?.toInt() ?? 0,
        username: map['username'] as String?,
        displayName: map['displayName'] as String?,
        pathImage: map['pathImage'] as String?,
        action: map['action'] as String? ?? '',
        expiresAt: map['expiresAt'] as String?,
        reason: map['reason'] as String?,
        moderatorId: (map['moderatorId'] as num?)?.toInt(),
        createdAt: map['createdAt'] as String?,
      );

  bool get isBan => action == 'ban';
  bool get isMute => action == 'mute';

  @override
  List<Object?> get props => [
    id,
    userId,
    username,
    displayName,
    pathImage,
    action,
    expiresAt,
    reason,
    moderatorId,
    createdAt,
  ];
}

// lib/domain/models/badge_user.dart
import 'package:disalive/domain/models/badge.dart';
import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:equatable/equatable.dart';

class BadgeUserModel extends Equatable {
  final int? id;
  final int? userId;
  final int? badgeId;
  final String? assignedAt;
  final bool? isVisible;
  final BadgeModel? badge;

  const BadgeUserModel({
    this.id,
    this.userId,
    this.badgeId,
    this.assignedAt,
    this.isVisible,
    this.badge,
  });

  factory BadgeUserModel.fromMap(Map<String, dynamic> map) {
    return BadgeUserModel(
      id: DataParser.parseInt(map['id']),
      userId: DataParser.parseInt(map['userId']),
      badgeId: DataParser.parseInt(map['badgeId']),
      assignedAt: map['assignedAt'],
      isVisible: DataParser.parseBool(map['isVisible']),
      badge: map['badge'] != null
          ? BadgeModel.fromMap(map['badge'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      if (badgeId != null) 'badgeId': badgeId,
      if (assignedAt != null) 'assignedAt': assignedAt,
      if (isVisible != null) 'isVisible': isVisible,
      if (badge != null) 'badge': badge?.toMap(),
    };
  }

  BadgeUserModel copyWith({
    int? id,
    int? userId,
    int? badgeId,
    String? assignedAt,
    bool? isVisible,
    BadgeModel? badge,
  }) {
    return BadgeUserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      badgeId: badgeId ?? this.badgeId,
      assignedAt: assignedAt ?? this.assignedAt,
      isVisible: isVisible ?? this.isVisible,
      badge: badge ?? this.badge,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    badgeId,
    assignedAt,
    isVisible,
    badge,
  ];
}

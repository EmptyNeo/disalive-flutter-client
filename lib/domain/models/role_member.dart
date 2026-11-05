// lib/domain/models/role_member.dart
import 'package:equatable/equatable.dart';

class RoleMember extends Equatable {
  final int? id;
  final int? entityId;
  final String? entityType;
  final String? name;
  final String? emoji;
  final String? color;
  final String? gradientStart;
  final String? gradientEnd;
  final int gradientAngle;
  final int sortOrder;
  final Map<String, bool>? permissions;

  const RoleMember({
    this.id,
    this.entityId,
    this.entityType,
    this.name,
    this.emoji,
    this.color,
    this.gradientStart,
    this.gradientEnd,
    this.gradientAngle = 90,
    this.sortOrder = 0,
    this.permissions,
  });

  factory RoleMember.fromMap(Map<String, dynamic> map) {
    Map<String, bool>? permissions;
    if (map['permissions'] != null) {
      if (map['permissions'] is Map<String, dynamic>) {
        final perms = map['permissions'] as Map<String, dynamic>;
        permissions = perms.map(
          (key, value) => MapEntry(key, value == true || value == 1),
        );
      }
    }

    return RoleMember(
      id: map['id'],
      entityId: map['entityId'],
      entityType: map['entityType'],
      name: map['name'],
      emoji: map['emoji'],
      color: _nullableHex(map['color']),
      gradientStart: _nullableHex(
        map['gradientStart'] ?? map['gradient_start'],
      ),
      gradientEnd: _nullableHex(map['gradientEnd'] ?? map['gradient_end']),
      gradientAngle:
          int.tryParse(
            '${map['gradientAngle'] ?? map['gradient_angle'] ?? 90}',
          ) ??
          90,
      sortOrder: int.tryParse('${map['sortOrder'] ?? 0}') ?? 0,
      permissions: permissions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (entityId != null) 'entityId': entityId,
      if (entityType != null) 'entityType': entityType,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      'color': color,
      'gradientStart': gradientStart,
      'gradientEnd': gradientEnd,
      'gradientAngle': gradientAngle,
      'sortOrder': sortOrder,
      if (permissions != null) 'permissions': permissions,
    };
  }

  RoleMember copyWith({
    int? id,
    int? entityId,
    String? entityType,
    String? name,
    String? emoji,
    String? color,
    String? gradientStart,
    String? gradientEnd,
    int? gradientAngle,
    int? sortOrder,
    Map<String, bool>? permissions,
  }) {
    return RoleMember(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      gradientAngle: gradientAngle ?? this.gradientAngle,
      sortOrder: sortOrder ?? this.sortOrder,
      permissions: permissions ?? this.permissions,
    );
  }

  bool hasPermission(String permission) {
    return permissions?[permission] ?? false;
  }

  @override
  List<Object?> get props => [
    id,
    entityId,
    entityType,
    name,
    emoji,
    color,
    gradientStart,
    gradientEnd,
    gradientAngle,
    sortOrder,
    permissions,
  ];
}

String? _nullableHex(Object? value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  final hex = value.toString().trim();
  return RegExp(r'^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$').hasMatch(hex)
      ? hex
      : null;
}

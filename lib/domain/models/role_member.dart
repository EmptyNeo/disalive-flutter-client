// lib/domain/models/role_member.dart
import 'package:equatable/equatable.dart';

class RoleMember extends Equatable {
  final int? id;
  final int? entityId;
  final String? entityType;
  final String? name;
  final String? emoji;
  final Map<String, bool>? permissions;

  const RoleMember({
    this.id,
    this.entityId,
    this.entityType,
    this.name,
    this.emoji,
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
      if (permissions != null) 'permissions': permissions,
    };
  }

  RoleMember copyWith({
    int? id,
    int? entityId,
    String? entityType,
    String? name,
    String? emoji,
    Map<String, bool>? permissions,
  }) {
    return RoleMember(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
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
    permissions,
  ];
}

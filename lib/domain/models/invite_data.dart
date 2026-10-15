// lib/domain/models/invite_data.dart
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:equatable/equatable.dart';

class InviteData extends Equatable {
  final int? id;
  final int? entityId;
  final String? entityType;
  final EntityKey? callEntity;
  final int? fkCreator;
  final String? code;
  final String? name;
  final String? pathAvatar;
  final int? memberCount;
  final int? onlineMemberCount;
  final bool? revoked;
  final String? expiresAt;
  final int? maxInvite;
  final int? currentCountInvite;
  final String? createdAt;
  final UserModel? user;

  const InviteData({
    this.id,
    this.entityId,
    this.entityType,
    this.callEntity,
    this.fkCreator,
    this.code,
    this.name,
    this.pathAvatar,
    this.memberCount,
    this.onlineMemberCount,
    this.revoked,
    this.expiresAt,
    this.maxInvite,
    this.currentCountInvite,
    this.createdAt,
    this.user,
  });

  factory InviteData.fromMap(Map<String, dynamic> map) {
    final rawCallEntity = map['callEntity'];
    final callEntityId = rawCallEntity is Map
        ? DataParser.parseInt(rawCallEntity['id'] ?? rawCallEntity['entityId'])
        : null;
    final callEntityType = rawCallEntity is Map
        ? rawCallEntity['type'] ?? rawCallEntity['entityType']
        : null;
    final callEntity = callEntityId != null && callEntityType is String
        ? EntityKey(
            entityId: callEntityId,
            entityType: EntityType.fromString(callEntityType),
          )
        : null;
    return InviteData(
      id: DataParser.parseInt(map['id']),
      entityId: DataParser.parseInt(map['entityId']),
      entityType: map['entityType'] as String?,
      callEntity: callEntity,
      fkCreator: DataParser.parseInt(map['fkCreator']),
      code: map['code'] as String?,
      name: map['name'],
      pathAvatar: map['pathAvatar'] ?? map['path_avatar'] ?? map['pathImage'],
      memberCount: DataParser.parseInt(map['memberCount']),
      onlineMemberCount: DataParser.parseInt(map['onlineMemberCount']),
      revoked: DataParser.parseBool(map['revoked']),
      expiresAt: map['expiresAt']?.toString(),
      maxInvite: DataParser.parseInt(map['maxInvite']),
      currentCountInvite: DataParser.parseInt(map['currentCountInvite']),
      createdAt: map['createdAt']?.toString(),
      user: map['user'] is Map<String, dynamic>
          ? UserModel.fromMap(map['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (entityId != null) 'entityId': entityId,
      if (entityType != null) 'entityType': entityType,
      if (callEntity != null)
        'callEntity': {
          'id': callEntity!.entityId,
          'type': callEntity!.entityType.value,
        },
      if (fkCreator != null) 'fkCreator': fkCreator,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (pathAvatar != null) 'pathAvatar': pathAvatar,
      if (memberCount != null) 'memberCount': memberCount,
      if (onlineMemberCount != null) 'onlineMemberCount': onlineMemberCount,
      if (revoked != null) 'revoked': revoked,
      if (expiresAt != null) 'expiresAt': expiresAt,
      if (maxInvite != null) 'maxInvite': maxInvite,
      if (currentCountInvite != null) 'currentCountInvite': currentCountInvite,
      if (createdAt != null) 'createdAt': createdAt,
      if (user != null) 'user': user!.toMap(),
    };
  }

  InviteData copyWith({
    int? id,
    int? entityId,
    String? entityType,
    EntityKey? callEntity,
    int? fkCreator,
    String? code,
    String? name,
    String? pathAvatar,
    int? memberCount,
    int? onlineMemberCount,
    bool? revoked,
    String? expiresAt,
    int? maxInvite,
    int? currentCountInvite,
    String? createdAt,
    UserModel? user,
  }) {
    return InviteData(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      callEntity: callEntity ?? this.callEntity,
      fkCreator: fkCreator ?? this.fkCreator,
      code: code ?? this.code,
      name: name ?? this.name,
      pathAvatar: pathAvatar ?? this.pathAvatar,
      memberCount: memberCount ?? this.memberCount,
      onlineMemberCount: onlineMemberCount ?? this.onlineMemberCount,
      revoked: revoked ?? this.revoked,
      expiresAt: expiresAt ?? this.expiresAt,
      maxInvite: maxInvite ?? this.maxInvite,
      currentCountInvite: currentCountInvite ?? this.currentCountInvite,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
    );
  }

  bool get isRevoked => revoked ?? false;

  bool get hasAvatar => pathAvatar != null && pathAvatar!.isNotEmpty;

  String? get inviteUrl => code == null
      ? null
      : Uri.parse(
          Domain.imageDomain,
        ).resolve('invite/${Uri.encodeComponent(code!)}').toString();

  @override
  List<Object?> get props => [
    id,
    entityId,
    entityType,
    callEntity,
    fkCreator,
    code,
    name,
    pathAvatar,
    memberCount,
    onlineMemberCount,
    revoked,
    expiresAt,
    maxInvite,
    currentCountInvite,
    createdAt,
    user,
  ];
}

class InviteDetails extends Equatable {
  final InviteData invite;
  final Server? server;

  const InviteDetails({required this.invite, this.server});

  factory InviteDetails.fromMap(Map<String, dynamic> map) => InviteDetails(
    invite: InviteData.fromMap(map['invite'] as Map<String, dynamic>),
    server: map['server'] is Map<String, dynamic>
        ? Server.fromMap(map['server'] as Map<String, dynamic>)
        : null,
  );

  @override
  List<Object?> get props => [invite, server];
}

class InviteAcceptance extends Equatable {
  final String? message;
  final Server? server;

  const InviteAcceptance({this.message, this.server});

  factory InviteAcceptance.fromMap(Map<String, dynamic> map) =>
      InviteAcceptance(
        message: map['message'] as String?,
        server: map['server'] is Map<String, dynamic>
            ? Server.fromMap(map['server'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [message, server];
}

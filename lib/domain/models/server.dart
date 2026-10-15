// lib/domain/models/server.dart
import 'package:disalive/domain/enums/server_type.dart';
import 'package:equatable/equatable.dart';

class Server extends Equatable {
  final int? id;
  final int? fkOwner;
  final String? name;
  final String? pathAvatar;
  final int? canInvite;
  final int? private;
  final ServerType? category;
  final int? fkMainChannel;
  final bool? isBlocked;
  final int? memberCount;
  final int? onlineMemberCount;
  final int? newMessagesCount;
  final List<int>? channelChatIds;
  final int? mainChatId;
  final int? roleId;
  final bool? isOwner;
  final bool? muted;
  final Map<String, bool>? permissions;

  const Server({
    this.id,
    this.fkOwner,
    this.name,
    this.pathAvatar,
    this.canInvite,
    this.private,
    this.category,
    this.fkMainChannel,
    this.isBlocked,
    this.memberCount,
    this.onlineMemberCount,
    this.newMessagesCount,
    this.channelChatIds,
    this.mainChatId,
    this.roleId,
    this.isOwner,
    this.muted,
    this.permissions,
  });

  factory Server.fromMap(Map<String, dynamic> map) {
    Map<String, bool>? permissions;
    if (map['permissions'] != null) {
      final perms = map['permissions'] as Map<String, dynamic>;
      permissions = perms.map(
        (key, value) => MapEntry(key, value == true || value == 1),
      );
    }

    List<int>? channelChatIds;
    if (map['channelChatIds'] != null && map['channelChatIds'] is List) {
      channelChatIds = (map['channelChatIds'] as List)
          .map((e) => e as int)
          .toList();
    }

    return Server(
      id: map['id'],
      fkOwner: map['fkOwner'],
      name: map['name'],
      pathAvatar: map['pathAvatar'],
      canInvite: map['canInvite'],
      private: map['private'],
      category: map['category'] == null
          ? null
          : ServerType.fromString(map['category'] as String?),
      fkMainChannel: map['fkMainChannel'],
      isBlocked: map['isBlocked'],
      memberCount: map['memberCount'],
      onlineMemberCount: map['onlineMemberCount'],
      newMessagesCount: map['newMessagesCount'],
      channelChatIds: channelChatIds,
      mainChatId: map['mainChatId'],
      roleId: map['roleId'],
      isOwner: map['isOwner'],
      muted: map['muted'],
      permissions: permissions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (fkOwner != null) 'fkOwner': fkOwner,
      if (name != null) 'name': name,
      if (pathAvatar != null) 'pathAvatar': pathAvatar,
      if (canInvite != null) 'canInvite': canInvite,
      if (private != null) 'private': private,
      if (category != null) 'category': category!.value,
      if (fkMainChannel != null) 'fkMainChannel': fkMainChannel,
      if (isBlocked != null) 'isBlocked': isBlocked,
      if (memberCount != null) 'memberCount': memberCount,
      if (onlineMemberCount != null) 'onlineMemberCount': onlineMemberCount,
      if (newMessagesCount != null) 'newMessagesCount': newMessagesCount,
      if (channelChatIds != null) 'channelChatIds': channelChatIds,
      if (mainChatId != null) 'mainChatId': mainChatId,
      if (roleId != null) 'roleId': roleId,
      if (isOwner != null) 'isOwner': isOwner,
      if (muted != null) 'muted': muted,
      if (permissions != null) 'permissions': permissions,
    };
  }

  Server copyWith({
    int? id,
    int? fkOwner,
    String? name,
    String? pathAvatar,
    int? canInvite,
    int? private,
    ServerType? category,
    int? fkMainChannel,
    bool? isBlocked,
    int? memberCount,
    int? onlineMemberCount,
    int? newMessagesCount,
    List<int>? channelChatIds,
    int? mainChatId,
    int? roleId,
    bool? isOwner,
    bool? muted,
    Map<String, bool>? permissions,
  }) {
    return Server(
      id: id ?? this.id,
      fkOwner: fkOwner ?? this.fkOwner,
      name: name ?? this.name,
      pathAvatar: pathAvatar ?? this.pathAvatar,
      canInvite: canInvite ?? this.canInvite,
      private: private ?? this.private,
      category: category ?? this.category,
      fkMainChannel: fkMainChannel ?? this.fkMainChannel,
      isBlocked: isBlocked ?? this.isBlocked,
      memberCount: memberCount ?? this.memberCount,
      onlineMemberCount: onlineMemberCount ?? this.onlineMemberCount,
      newMessagesCount: newMessagesCount ?? this.newMessagesCount,
      channelChatIds: channelChatIds ?? this.channelChatIds,
      mainChatId: mainChatId ?? this.mainChatId,
      roleId: roleId ?? this.roleId,
      isOwner: isOwner ?? this.isOwner,
      muted: muted ?? this.muted,
      permissions: permissions ?? this.permissions,
    );
  }

  // Вспомогательные геттеры
  bool get isServerOwner => isOwner ?? false;
  bool get isServerMuted => muted ?? false;
  bool get canInviteUsers => canInvite == 1;
  bool get isPrivate => private == 1;
  bool get isServerBlocked => isBlocked ?? false;
  bool get hasPermissions => permissions != null && permissions!.isNotEmpty;

  bool hasPermission(String permission) {
    return permissions?[permission] ?? false;
  }

  @override
  List<Object?> get props => [
    id,
    fkOwner,
    name,
    pathAvatar,
    canInvite,
    private,
    category,
    fkMainChannel,
    isBlocked,
    memberCount,
    onlineMemberCount,
    newMessagesCount,
    channelChatIds,
    mainChatId,
    roleId,
    isOwner,
    muted,
    permissions,
  ];
}

// lib/domain/models/chat.dart
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:equatable/equatable.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'dart:math' as math;

class Chat extends Equatable {
  final int id;
  final int? fkCreator;
  final int? roleId;
  final int? idLastMessage;
  final int? newMessagesCount;
  final int? memberCount;
  final String name;
  final String? pathImage;
  final ChatType? type;
  final String? lastActionTime;
  final String? lastMessageTime;
  final bool? isBlocked;
  final bool? isCreator;
  final bool? isPersonal;
  final bool? isSoloChat;
  final int? idCreator;
  final Member? member;
  final RoleMember? role;
  final UserModel? user;

  const Chat({
    required this.id,
    this.fkCreator,
    this.roleId,
    this.idLastMessage,
    this.newMessagesCount,
    this.memberCount,
    required this.name,
    this.pathImage,
    this.type,
    this.lastActionTime,
    this.lastMessageTime,
    this.isBlocked,
    this.isCreator,
    this.isPersonal,
    this.isSoloChat,
    this.idCreator,
    this.member,
    this.role,
    this.user,
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['chatId'],
      fkCreator: map['fkCreator'],
      roleId: map['roleId'],
      idLastMessage: map['idLastMessage'],
      newMessagesCount: map['newMessagesCount'],
      memberCount: map['memberCount'],
      name: map['name'],
      pathImage: map['pathImage'],
      type: map['type'] != null
          ? ChatType.fromString(map['type'] as String)
          : null,
      lastActionTime: map['lastActionTime'],
      lastMessageTime: map['lastMessageTime'],
      isBlocked: map['isBlocked'],
      isCreator: map['isCreator'],
      isPersonal: map['isPersonal'],
      isSoloChat: map['isSoloChat'],
      idCreator: map['idCreator'],
      member: map['member'] != null
          ? Member.fromMap(map['member'] as Map<String, dynamic>)
          : null,
      role: map['role'] != null
          ? RoleMember.fromMap(map['role'] as Map<String, dynamic>)
          : null,
      user: map['user'] != null
          ? UserModel.fromMap(map['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': id,
      if (fkCreator != null) 'fkCreator': fkCreator,
      if (roleId != null) 'roleId': roleId,
      if (idLastMessage != null) 'idLastMessage': idLastMessage,
      if (newMessagesCount != null) 'newMessagesCount': newMessagesCount,
      if (memberCount != null) 'memberCount': memberCount,
      'name': name,
      if (pathImage != null) 'pathImage': pathImage,
      if (type != null) 'type': type,
      if (lastActionTime != null) 'lastActionTime': lastActionTime,
      if (lastMessageTime != null) 'lastMessageTime': lastMessageTime,
      if (isBlocked != null) 'isBlocked': isBlocked,
      if (isCreator != null) 'isCreator': isCreator,
      if (isPersonal != null) 'isPersonal': isPersonal,
      if (isSoloChat != null) 'isSoloChat': isSoloChat,
      if (idCreator != null) 'idCreator': idCreator,
      if (member != null) 'member': member?.toMap(),
      if (role != null) 'role': role?.toMap(),
      if (user != null) 'user': user?.toMap(),
    };
  }

  Chat copyWith({
    int? chatId,
    int? fkCreator,
    int? roleId,
    int? idLastMessage,
    int? newMessagesCount,
    int? memberCount,
    String? name,
    String? pathImage,
    ChatType? type,
    String? lastActionTime,
    String? lastMessageTime,
    bool? isBlocked,
    bool? isCreator,
    bool? isPersonal,
    bool? isSoloChat,
    int? idCreator,
    Member? member,
    RoleMember? role,
    UserModel? user,
  }) {
    return Chat(
      id: chatId ?? id,
      fkCreator: fkCreator ?? this.fkCreator,
      roleId: roleId ?? this.roleId,
      idLastMessage: idLastMessage ?? this.idLastMessage,
      newMessagesCount: newMessagesCount ?? this.newMessagesCount,
      memberCount: memberCount ?? this.memberCount,
      name: name ?? this.name,
      pathImage: pathImage ?? this.pathImage,
      type: type ?? this.type,
      lastActionTime: lastActionTime ?? this.lastActionTime,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isBlocked: isBlocked ?? this.isBlocked,
      isCreator: isCreator ?? this.isCreator,
      isPersonal: isPersonal ?? this.isPersonal,
      isSoloChat: isSoloChat ?? this.isSoloChat,
      idCreator: idCreator ?? this.idCreator,
      member: member ?? this.member,
      role: role ?? this.role,
      user: user ?? this.user,
    );
  }

  bool get hasUnreadMessages => unreadCount > 0;

  bool get isPersonalChat => isPersonal ?? false;

  bool get isGroup => !(isPersonal ?? false) && !(isSoloChat ?? false);

  bool get isSolo => isSoloChat ?? false;

  bool get isOwner => isCreator ?? false;

  bool get isChatBlocked => isBlocked ?? false;

  bool get isAnyBlocked => user?.isAnyBlocked ?? false;

  String get urlAvatar => Domain.transformUrl(pathImage);

  int get unreadCount =>
      math.max(0, (idLastMessage ?? 0) - (member?.lastIdReadMessage ?? 0));

  @override
  List<Object?> get props => [
    id,
    fkCreator,
    roleId,
    idLastMessage,
    newMessagesCount,
    memberCount,
    name,
    pathImage,
    type,
    lastActionTime,
    lastMessageTime,
    isBlocked,
    isCreator,
    isPersonal,
    isSoloChat,
    idCreator,
    member,
    role,
    user,
  ];
}

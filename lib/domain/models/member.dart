// lib/domain/models/member.dart
import 'package:disalive/domain/models/user.dart';
import 'package:equatable/equatable.dart';
import 'package:disalive/domain/models/role_member.dart';

class Member extends Equatable {
  final int? id;
  final int? fkUser;
  final int? fkRole;
  final int? lastIdReadMessage;
  final bool? muted;
  final bool? fixed;
  final int? orderFixed;
  final bool? isSelf;
  final bool? isCreator;
  final bool? isBanned;
  final String? banExpiresAt;
  final bool? isChatMuted;
  final String? chatMuteExpiresAt;
  final UserModel? user;
  final RoleMember? role;

  const Member({
    this.id,
    this.fkUser,
    this.fkRole,
    this.lastIdReadMessage,
    this.muted,
    this.fixed,
    this.orderFixed,
    this.isSelf,
    this.isCreator,
    this.isBanned,
    this.banExpiresAt,
    this.isChatMuted,
    this.chatMuteExpiresAt,
    this.user,
    this.role,
  });

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      fkUser: _parseInt(map['fkUser'] ?? map['userId']),
      fkRole: map['fkRole'],
      lastIdReadMessage: _parseInt(map['lastIdReadMessage']),
      muted: map['muted'],
      fixed: map['fixed'],
      orderFixed: map['orderFixed'],
      isSelf: _parseBool(map['isSelf']),
      isCreator: map['isCreator'],
      isBanned: _parseBool(map['isBanned']),
      banExpiresAt: map['banExpiresAt'] as String?,
      isChatMuted: _parseBool(map['isChatMuted']),
      chatMuteExpiresAt: map['chatMuteExpiresAt'] as String?,
      user: map['user'] != null
          ? UserModel.fromMap(map['user'] as Map<String, dynamic>)
          : null,
      role: map['role'] != null
          ? RoleMember.fromMap(map['role'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (fkUser != null) 'fkUser': fkUser,
      if (fkRole != null) 'fkRole': fkRole,
      if (lastIdReadMessage != null) 'lastIdReadMessage': lastIdReadMessage,
      if (muted != null) 'muted': muted,
      if (fixed != null) 'fixed': fixed,
      if (orderFixed != null) 'orderFixed': orderFixed,
      if (isSelf != null) 'isSelf': isSelf,
      if (isCreator != null) 'isCreator': isCreator,
      if (isBanned != null) 'isBanned': isBanned,
      if (banExpiresAt != null) 'banExpiresAt': banExpiresAt,
      if (isChatMuted != null) 'isChatMuted': isChatMuted,
      if (chatMuteExpiresAt != null) 'chatMuteExpiresAt': chatMuteExpiresAt,
      if (user != null) 'user': user?.toMap(),
      if (role != null) 'role': role?.toMap(),
    };
  }

  Member copyWith({
    int? id,
    int? fkUser,
    int? fkRole,
    int? lastIdReadMessage,
    bool? muted,
    bool? fixed,
    int? orderFixed,
    bool? isSelf,
    bool? isCreator,
    bool? isBanned,
    String? banExpiresAt,
    bool clearBanExpiresAt = false,
    bool? isChatMuted,
    String? chatMuteExpiresAt,
    bool clearChatMuteExpiresAt = false,
    UserModel? user,
    RoleMember? role,
  }) {
    return Member(
      id: id ?? this.id,
      fkUser: fkUser ?? this.fkUser,
      fkRole: fkRole ?? this.fkRole,
      lastIdReadMessage: lastIdReadMessage ?? this.lastIdReadMessage,
      muted: muted ?? this.muted,
      fixed: fixed ?? this.fixed,
      orderFixed: orderFixed ?? this.orderFixed,
      isSelf: isSelf ?? this.isSelf,
      isCreator: isCreator ?? this.isCreator,
      isBanned: isBanned ?? this.isBanned,
      banExpiresAt: clearBanExpiresAt
          ? null
          : (banExpiresAt ?? this.banExpiresAt),
      isChatMuted: isChatMuted ?? this.isChatMuted,
      chatMuteExpiresAt: clearChatMuteExpiresAt
          ? null
          : (chatMuteExpiresAt ?? this.chatMuteExpiresAt),
      user: user ?? this.user,
      role: role ?? this.role,
    );
  }

  bool get isMuted => muted ?? false;
  bool get isFixed => fixed ?? false;
  bool get isCurrentUser => isSelf ?? false;
  bool get isChatOwner => isCreator ?? false;

  @override
  List<Object?> get props => [
    id,
    fkUser,
    fkRole,
    lastIdReadMessage,
    muted,
    fixed,
    orderFixed,
    isSelf,
    isCreator,
    isBanned,
    banExpiresAt,
    isChatMuted,
    chatMuteExpiresAt,
    user,
    role,
  ];
}

bool? _parseBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

int? _parseInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

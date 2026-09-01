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
    this.user,
    this.role,
  });

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      fkUser: map['fkUser'],
      fkRole: map['fkRole'],
      lastIdReadMessage: map['lastIdReadMessage'],
      muted: map['muted'],
      fixed: map['fixed'],
      orderFixed: map['orderFixed'],
      isSelf: map['isSelf'],
      isCreator: map['isCreator'],
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
    user,
    role,
  ];
}
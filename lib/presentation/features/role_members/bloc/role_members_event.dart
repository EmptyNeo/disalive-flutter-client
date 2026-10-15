part of 'role_members_bloc.dart';

abstract class RoleMembersEvent extends Equatable {
  const RoleMembersEvent();
}

class GetRoleMembers extends RoleMembersEvent {
  const GetRoleMembers();

  @override
  List<Object?> get props => [];
}

class RoleMemberUpserted extends RoleMembersEvent {
  const RoleMemberUpserted(this.roleData);
  final Map<String, dynamic> roleData;

  @override
  List<Object?> get props => [roleData];
}

class RoleMemberRemoved extends RoleMembersEvent {
  const RoleMemberRemoved(this.roleId);
  final int roleId;

  @override
  List<Object?> get props => [roleId];
}

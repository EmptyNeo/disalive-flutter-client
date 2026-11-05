part of 'role_members_bloc.dart';

abstract class RoleMembersState extends Equatable {
  const RoleMembersState();
}

class RoleMembersInitial extends RoleMembersState {
  const RoleMembersInitial();
  @override
  List<Object?> get props => [];
}

class RoleMembersLoading extends RoleMembersState {
  const RoleMembersLoading();
  @override
  List<Object?> get props => [];
}

class RoleMembersLoaded extends RoleMembersState {
  const RoleMembersLoaded(
    this.roles, {
    this.isSavingOrder = false,
    this.orderError,
  });
  final List<RoleMember> roles;
  final bool isSavingOrder;
  final String? orderError;

  @override
  List<Object?> get props => [roles, isSavingOrder, orderError];
}

class RoleMembersFailure extends RoleMembersState {
  const RoleMembersFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

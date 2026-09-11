// presentation/features/members/bloc/members_state.dart
part of 'members_bloc.dart';

abstract class MembersState extends Equatable {
  const MembersState();

  @override
  List<Object?> get props => [];
}

class MembersInitial extends MembersState {}

class MembersLoading extends MembersState {}

class MembersLoaded extends MembersState {
  final int entityId;
  final EntityType entityType;
  final List<Member> members;
  final int memberCount;

  const MembersLoaded({
    required this.entityId,
    required this.entityType,
    required this.members,
    this.memberCount = 0,
  });

  @override
  List<Object?> get props => [entityId, entityType, members, memberCount];
}

class MembersFailure extends MembersState {
  final String message;

  const MembersFailure(this.message);

  @override
  List<Object?> get props => [message];
}

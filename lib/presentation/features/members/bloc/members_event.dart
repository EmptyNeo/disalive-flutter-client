// presentation/features/members/bloc/members_event.dart
part of 'members_bloc.dart';

abstract class MembersEvent extends Equatable {
  const MembersEvent();

  @override
  List<Object?> get props => [];
}

class GetMembers extends MembersEvent {
  final int entityId;
  final EntityType entityType;

  const GetMembers({required this.entityId, required this.entityType});

  @override
  List<Object?> get props => [entityId, entityType];
}

// --- WebSocket События ---

class MemberAddedEvent extends MembersEvent {
  final int entityId;
  final EntityType entityType;
  final List<Member> newMembers;
  final int memberCount;

  const MemberAddedEvent({
    required this.entityId,
    required this.entityType,
    required this.newMembers,
    required this.memberCount,
  });

  @override
  List<Object?> get props => [entityId, entityType, newMembers, memberCount];
}

class MemberRemovedEvent extends MembersEvent {
  final int entityId;
  final EntityType entityType;
  final int removedUserId;
  final int memberCount;

  const MemberRemovedEvent({
    required this.entityId,
    required this.entityType,
    required this.removedUserId,
    required this.memberCount,
  });

  @override
  List<Object?> get props => [entityId, entityType, removedUserId, memberCount];
}

class MemberUpdatedEvent extends MembersEvent {
  final int entityId;
  final EntityType entityType;
  final List<Member> updatedMembers;

  const MemberUpdatedEvent({
    required this.entityId,
    required this.entityType,
    required this.updatedMembers,
  });

  @override
  List<Object?> get props => [entityId, entityType, updatedMembers];
}

part of 'invites_bloc.dart';

sealed class InvitesEvent extends Equatable {
  const InvitesEvent();

  @override
  List<Object?> get props => [];
}

class LoadServerInvites extends InvitesEvent {
  const LoadServerInvites(this.serverId);

  final int serverId;

  @override
  List<Object?> get props => [serverId];
}

class GenerateInviteCode extends InvitesEvent {
  const GenerateInviteCode();
}

class CreateInvite extends InvitesEvent {
  const CreateInvite({
    required this.entityId,
    required this.entityType,
    required this.code,
    this.callEntity,
    this.targetChatId,
    this.maxUsers = 0,
    this.expiresAt,
  });

  final int entityId;
  final EntityType entityType;
  final String code;
  final EntityKey? callEntity;
  final int? targetChatId;
  final int maxUsers;
  final int? expiresAt;

  @override
  List<Object?> get props => [
    entityId,
    entityType,
    code,
    callEntity,
    targetChatId,
    maxUsers,
    expiresAt,
  ];
}

class LookupInvite extends InvitesEvent {
  const LookupInvite(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

class AcceptInvite extends InvitesEvent {
  const AcceptInvite(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

class RevokeInvite extends InvitesEvent {
  const RevokeInvite(this.inviteId);

  final int inviteId;

  @override
  List<Object?> get props => [inviteId];
}

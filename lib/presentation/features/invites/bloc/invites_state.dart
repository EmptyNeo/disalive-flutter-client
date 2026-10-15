part of 'invites_bloc.dart';

enum InviteOperation { load, generate, create, lookup, accept, revoke }

const _unchanged = Object();

class InvitesState extends Equatable {
  const InvitesState({
    this.serverId,
    this.invites = const [],
    this.pending = const {},
    this.failures = const {},
    this.generatedCode,
    this.createdInvite,
    this.details,
    this.acceptance,
    this.revokedId,
    this.lastCompleted,
  });

  final int? serverId;
  final List<InviteData> invites;
  final Set<InviteOperation> pending;
  final Map<InviteOperation, Failure> failures;
  final String? generatedCode;
  final InviteData? createdInvite;
  final InviteDetails? details;
  final InviteAcceptance? acceptance;
  final int? revokedId;
  final InviteOperation? lastCompleted;

  bool isPending(InviteOperation operation) => pending.contains(operation);
  Failure? failureFor(InviteOperation operation) => failures[operation];

  InvitesState copyWith({
    int? serverId,
    List<InviteData>? invites,
    Set<InviteOperation>? pending,
    Map<InviteOperation, Failure>? failures,
    Object? generatedCode = _unchanged,
    Object? createdInvite = _unchanged,
    Object? details = _unchanged,
    Object? acceptance = _unchanged,
    Object? revokedId = _unchanged,
    Object? lastCompleted = _unchanged,
  }) => InvitesState(
    serverId: serverId ?? this.serverId,
    invites: invites ?? this.invites,
    pending: pending ?? this.pending,
    failures: failures ?? this.failures,
    generatedCode: identical(generatedCode, _unchanged)
        ? this.generatedCode
        : generatedCode as String?,
    createdInvite: identical(createdInvite, _unchanged)
        ? this.createdInvite
        : createdInvite as InviteData?,
    details: identical(details, _unchanged)
        ? this.details
        : details as InviteDetails?,
    acceptance: identical(acceptance, _unchanged)
        ? this.acceptance
        : acceptance as InviteAcceptance?,
    revokedId: identical(revokedId, _unchanged)
        ? this.revokedId
        : revokedId as int?,
    lastCompleted: identical(lastCompleted, _unchanged)
        ? this.lastCompleted
        : lastCompleted as InviteOperation?,
  );

  @override
  List<Object?> get props => [
    serverId,
    invites,
    pending,
    failures,
    generatedCode,
    createdInvite,
    details,
    acceptance,
    revokedId,
    lastCompleted,
  ];
}

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/invite_data.dart';
import 'package:disalive/domain/repositories/invite_repository.dart';
import 'package:equatable/equatable.dart';

part 'invites_event.dart';
part 'invites_state.dart';

class InvitesBloc extends Bloc<InvitesEvent, InvitesState> {
  InvitesBloc(this._repository) : super(const InvitesState()) {
    on<LoadServerInvites>(_load);
    on<GenerateInviteCode>(_generate);
    on<CreateInvite>(_create);
    on<LookupInvite>(_lookup);
    on<AcceptInvite>(_accept);
    on<RevokeInvite>(_revoke);
  }

  final InviteRepository _repository;
  final List<({InviteData? invite, int? revokedId})> _changesDuringLoad = [];
  int _loadGeneration = 0;
  int _lookupGeneration = 0;

  void _start(InviteOperation operation, Emitter<InvitesState> emit) {
    final failures = Map<InviteOperation, Failure>.from(state.failures)
      ..remove(operation);
    emit(
      state.copyWith(
        pending: {...state.pending, operation},
        failures: failures,
        lastCompleted: null,
      ),
    );
  }

  void _complete(InviteOperation operation, Emitter<InvitesState> emit) {
    emit(
      state.copyWith(
        pending: {...state.pending}..remove(operation),
        lastCompleted: operation,
      ),
    );
  }

  void _fail(
    InviteOperation operation,
    Failure failure,
    Emitter<InvitesState> emit,
  ) {
    emit(
      state.copyWith(
        pending: {...state.pending}..remove(operation),
        failures: {...state.failures, operation: failure},
        lastCompleted: null,
      ),
    );
  }

  Future<void> _load(
    LoadServerInvites event,
    Emitter<InvitesState> emit,
  ) async {
    if (state.serverId == event.serverId &&
        state.isPending(InviteOperation.load)) {
      return;
    }
    final generation = ++_loadGeneration;
    _changesDuringLoad.clear();
    final cached = _repository.getCached(event.serverId);
    emit(
      state.copyWith(
        serverId: event.serverId,
        invites: List.unmodifiable(cached),
      ),
    );
    _start(InviteOperation.load, emit);
    final result = await _repository.getForServer(event.serverId);
    if (generation != _loadGeneration || isClosed) return;
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            invites: List.unmodifiable(_repository.getCached(event.serverId)),
          ),
        );
        _fail(InviteOperation.load, failure, emit);
      },
      (loaded) {
        final invites = List<InviteData>.from(loaded);
        for (final change in _changesDuringLoad) {
          if (change.invite != null) {
            _upsert(invites, change.invite!);
          } else if (change.revokedId != null) {
            _markRevoked(invites, change.revokedId!);
          }
        }
        _repository.updateCache(event.serverId, invites);
        emit(state.copyWith(invites: List.unmodifiable(invites)));
        _complete(InviteOperation.load, emit);
      },
    );
    _changesDuringLoad.clear();
  }

  Future<void> _generate(
    GenerateInviteCode event,
    Emitter<InvitesState> emit,
  ) async {
    if (state.isPending(InviteOperation.generate)) return;
    _start(InviteOperation.generate, emit);
    emit(state.copyWith(generatedCode: null));
    final result = await _repository.generateCode();
    if (isClosed) return;
    result.fold((failure) => _fail(InviteOperation.generate, failure, emit), (
      code,
    ) {
      emit(state.copyWith(generatedCode: code));
      _complete(InviteOperation.generate, emit);
    });
  }

  Future<void> _create(CreateInvite event, Emitter<InvitesState> emit) async {
    if (state.isPending(InviteOperation.create)) return;
    _start(InviteOperation.create, emit);
    emit(state.copyWith(createdInvite: null));
    final result = await _repository.create(
      event.entityId,
      event.entityType,
      event.code,
      callEntity: event.callEntity,
      maxUsers: event.maxUsers,
      expiresAt: event.expiresAt,
    );
    if (isClosed) return;
    result.fold((failure) => _fail(InviteOperation.create, failure, emit), (
      invite,
    ) {
      if (event.entityType == EntityType.server &&
          state.serverId == event.entityId &&
          invite.id != null) {
        if (state.isPending(InviteOperation.load)) {
          _changesDuringLoad.add((invite: invite, revokedId: null));
        }
        final invites = List<InviteData>.from(state.invites);
        _upsert(invites, invite);
        _repository.updateCache(event.entityId, invites);
        emit(state.copyWith(invites: List.unmodifiable(invites)));
      }
      emit(state.copyWith(createdInvite: invite));
      _complete(InviteOperation.create, emit);
    });
  }

  Future<void> _lookup(LookupInvite event, Emitter<InvitesState> emit) async {
    final generation = ++_lookupGeneration;
    _start(InviteOperation.lookup, emit);
    emit(state.copyWith(details: null));
    final result = await _repository.getByCode(event.code);
    if (generation != _lookupGeneration || isClosed) return;
    result.fold((failure) => _fail(InviteOperation.lookup, failure, emit), (
      details,
    ) {
      emit(state.copyWith(details: details));
      _complete(InviteOperation.lookup, emit);
    });
  }

  Future<void> _accept(AcceptInvite event, Emitter<InvitesState> emit) async {
    if (state.isPending(InviteOperation.accept)) return;
    _start(InviteOperation.accept, emit);
    emit(state.copyWith(acceptance: null));
    final result = await _repository.accept(event.code);
    if (isClosed) return;
    result.fold((failure) => _fail(InviteOperation.accept, failure, emit), (
      acceptance,
    ) {
      emit(state.copyWith(acceptance: acceptance));
      _complete(InviteOperation.accept, emit);
    });
  }

  Future<void> _revoke(RevokeInvite event, Emitter<InvitesState> emit) async {
    if (state.isPending(InviteOperation.revoke)) return;
    _start(InviteOperation.revoke, emit);
    emit(state.copyWith(revokedId: null));
    final result = await _repository.revoke(event.inviteId);
    if (isClosed) return;
    result.fold((failure) => _fail(InviteOperation.revoke, failure, emit), (
      revoked,
    ) {
      if (!revoked) {
        _fail(
          InviteOperation.revoke,
          ClientFailure('Не удалось отозвать приглашение'),
          emit,
        );
        return;
      }
      if (state.serverId != null) {
        if (state.isPending(InviteOperation.load)) {
          _changesDuringLoad.add((invite: null, revokedId: event.inviteId));
        }
        final invites = List<InviteData>.from(state.invites);
        _markRevoked(invites, event.inviteId);
        _repository.updateCache(state.serverId!, invites);
        emit(state.copyWith(invites: List.unmodifiable(invites)));
      }
      emit(state.copyWith(revokedId: event.inviteId));
      _complete(InviteOperation.revoke, emit);
    });
  }

  void _upsert(List<InviteData> invites, InviteData invite) {
    if (invite.id == null) return;
    final index = invites.indexWhere((item) => item.id == invite.id);
    if (index < 0) {
      invites.add(invite);
    } else {
      invites[index] = invite;
    }
  }

  void _markRevoked(List<InviteData> invites, int inviteId) {
    final index = invites.indexWhere((item) => item.id == inviteId);
    if (index >= 0) invites[index] = invites[index].copyWith(revoked: true);
  }
}

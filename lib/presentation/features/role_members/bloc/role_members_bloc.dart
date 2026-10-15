import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/role_member_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:equatable/equatable.dart';

part 'role_members_event.dart';
part 'role_members_state.dart';

class RoleMembersBloc extends Bloc<RoleMembersEvent, RoleMembersState> {
  RoleMembersBloc(
    this._repository,
    WsEventBus eventBus, {
    required this.entityId,
    required this.entityType,
  }) : super(const RoleMembersInitial()) {
    on<GetRoleMembers>(_load);
    on<RoleMemberUpserted>(_upsert);
    on<RoleMemberRemoved>(_remove);
    _subscription = eventBus.subscribeToTable(
      table: 'RoleMembers',
      onData: _onWsEvent,
    );
  }

  final RoleMemberRepository _repository;
  final int entityId;
  final EntityType entityType;
  StreamSubscription<WsEvent>? _subscription;
  final List<RoleMembersEvent> _changesDuringLoad = [];
  bool _loading = false;

  EntityKey get _key => EntityKey(entityId: entityId, entityType: entityType);

  void _onWsEvent(WsEvent event) {
    final data = event.data;
    if (DataParser.parseInt(data['entityId']) != entityId ||
        data['entityType'] != entityType.value) {
      return;
    }
    if (event.action == ActionType.create ||
        event.action == ActionType.update) {
      final role = data['role'];
      if (role is Map) {
        add(RoleMemberUpserted(Map<String, dynamic>.from(role)));
      }
    } else if (event.action == ActionType.delete) {
      final id = DataParser.parseInt(data['roleId']);
      if (id != null) add(RoleMemberRemoved(id));
    }
  }

  Future<void> _load(
    GetRoleMembers event,
    Emitter<RoleMembersState> emit,
  ) async {
    if (_loading) return;
    _loading = true;
    _changesDuringLoad.clear();
    final cached = _repository.getCached(_key);
    emit(
      cached.isEmpty ? const RoleMembersLoading() : RoleMembersLoaded(cached),
    );
    final result = await _repository.get(entityId, entityType);
    _loading = false;
    result.fold(
      (failure) {
        final current = _repository.getCached(_key);
        emit(
          current.isEmpty
              ? RoleMembersFailure(failure.message)
              : RoleMembersLoaded(current),
        );
      },
      (roles) {
        final merged = List<RoleMember>.from(roles);
        for (final change in _changesDuringLoad) {
          if (change is RoleMemberUpserted) {
            _applyUpsert(merged, change.roleData);
          } else if (change is RoleMemberRemoved) {
            merged.removeWhere((role) => role.id == change.roleId);
          }
        }
        _repository.updateCache(_key, merged);
        emit(RoleMembersLoaded(List.unmodifiable(merged)));
      },
    );
    _changesDuringLoad.clear();
  }

  void _upsert(RoleMemberUpserted event, Emitter<RoleMembersState> emit) {
    if (_loading) _changesDuringLoad.add(event);
    final roles = List<RoleMember>.from(_repository.getCached(_key));
    _applyUpsert(roles, event.roleData);
    _repository.updateCache(_key, roles);
    emit(RoleMembersLoaded(List.unmodifiable(roles)));
  }

  void _applyUpsert(List<RoleMember> roles, Map<String, dynamic> data) {
    final id = DataParser.parseInt(data['id']);
    if (id == null) return;
    final index = roles.indexWhere((role) => role.id == id);
    final previous = index < 0 ? null : roles[index];
    final role = RoleMember.fromMap({
      if (previous != null) ...previous.toMap(),
      ...data,
      'id': id,
      'entityId': entityId,
      'entityType': entityType.value,
    });
    if (index < 0) {
      roles.add(role);
    } else {
      roles[index] = role;
    }
  }

  void _remove(RoleMemberRemoved event, Emitter<RoleMembersState> emit) {
    if (_loading) _changesDuringLoad.add(event);
    final roles = List<RoleMember>.from(_repository.getCached(_key))
      ..removeWhere((role) => role.id == event.roleId);
    _repository.updateCache(_key, roles);
    emit(RoleMembersLoaded(List.unmodifiable(roles)));
  }

  Future<Either<Failure, RoleMember>> createRole() async {
    final result = await _repository.create(entityId, entityType);
    result.fold((_) {}, (role) => add(RoleMemberUpserted(role.toMap())));
    return result;
  }

  Future<Either<Failure, RoleMember>> updateRole(
    RoleMember role, {
    required String name,
    required String? emoji,
    required Map<String, bool> permissions,
  }) async {
    final result = await _repository.update(
      role.id!,
      entityId,
      entityType,
      name: name,
      emoji: emoji ?? '',
      permissions: permissions,
    );
    result.fold((_) {}, (updated) => add(RoleMemberUpserted(updated.toMap())));
    return result;
  }

  Future<Either<Failure, bool>> deleteRole(int roleId) async {
    final result = await _repository.delete(roleId, entityId, entityType);
    result.fold((_) {}, (deleted) {
      if (deleted) add(RoleMemberRemoved(roleId));
    });
    return result;
  }

  Future<Either<Failure, bool>> assignRole(int roleId, List<int> userIds) =>
      _repository.assign(roleId, entityId, entityType, userIds);

  Future<Either<Failure, bool>> unassignRole(int roleId, int userId) =>
      _repository.unassign(roleId, entityId, entityType, userId);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}

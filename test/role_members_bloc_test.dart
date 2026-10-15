import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/role_member_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/role_members/bloc/role_members_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _RolesRepository implements RoleMemberRepository {
  final Map<EntityKey, List<RoleMember>> cache = {};
  final Completer<void> release = Completer<void>();

  @override
  Future<Either<Failure, List<RoleMember>>> get(int id, EntityType type) async {
    await release.future;
    final roles = [const RoleMember(id: 1, name: 'Старая роль')];
    updateCache(EntityKey(entityId: id, entityType: type), roles);
    return Right(roles);
  }

  @override
  List<RoleMember> getCached(EntityKey key) => List.of(cache[key] ?? []);

  @override
  void updateCache(EntityKey key, List<RoleMember> roles) {
    cache[key] = List.of(roles);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'RoleMembersBloc filters entities and replays WS changes during load',
    () async {
      final repo = _RolesRepository();
      final bus = WsEventBus();
      final bloc = RoleMembersBloc(
        repo,
        bus,
        entityId: 7,
        entityType: EntityType.server,
      );
      bloc.add(const GetRoleMembers());
      await bloc.stream.firstWhere((state) => state is RoleMembersLoading);

      bus.dispatch(
        WsEvent(
          table: 'RoleMembers',
          action: ActionType.create,
          data: {
            'entityId': 8,
            'entityType': 'server',
            'role': {'id': 9, 'name': 'Другая'},
          },
          isSelf: false,
        ),
      );
      bus.dispatch(
        WsEvent(
          table: 'RoleMembers',
          action: ActionType.create,
          data: {
            'entityId': 7,
            'entityType': 'server',
            'role': {'id': 2, 'name': 'Новая роль'},
          },
          isSelf: true,
        ),
      );
      await bloc.stream.firstWhere(
        (state) => state is RoleMembersLoaded && state.roles.length == 1,
      );
      repo.release.complete();
      final loaded =
          await bloc.stream.firstWhere(
                (state) =>
                    state is RoleMembersLoaded && state.roles.length == 2,
              )
              as RoleMembersLoaded;
      expect(loaded.roles.map((role) => role.id), containsAll([1, 2]));
      expect(loaded.roles.map((role) => role.id), isNot(contains(9)));

      bus.dispatch(
        WsEvent(
          table: 'RoleMembers',
          action: ActionType.update,
          data: {
            'entityId': 7,
            'entityType': 'server',
            'role': {'id': 2, 'emoji': '[people:1]'},
          },
          isSelf: false,
        ),
      );
      final updated =
          await bloc.stream.firstWhere(
                (state) =>
                    state is RoleMembersLoaded &&
                    state.roles.any(
                      (role) => role.id == 2 && role.emoji != null,
                    ),
              )
              as RoleMembersLoaded;
      expect(
        updated.roles.firstWhere((role) => role.id == 2).name,
        'Новая роль',
      );

      bus.dispatch(
        WsEvent(
          table: 'RoleMembers',
          action: ActionType.delete,
          data: {'entityId': 7, 'entityType': 'server', 'roleId': 2},
          isSelf: false,
        ),
      );
      final removed =
          await bloc.stream.firstWhere(
                (state) =>
                    state is RoleMembersLoaded && state.roles.length == 1,
              )
              as RoleMembersLoaded;
      expect(removed.roles.single.id, 1);
      await bloc.close();
      bus.dispose();
    },
  );
}

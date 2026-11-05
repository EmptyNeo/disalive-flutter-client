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
  Future<Either<Failure, List<RoleMember>>> reorder(
    int entityId,
    EntityType entityType,
    List<int> roleIds,
  ) async {
    final key = EntityKey(entityId: entityId, entityType: entityType);
    final byId = {
      for (final role in cache[key] ?? <RoleMember>[]) role.id: role,
    };
    final roles = [
      for (var index = 0; index < roleIds.length; index++)
        byId[roleIds[index]]!.copyWith(sortOrder: index),
    ];
    updateCache(key, roles);
    return Right(roles);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('RoleMembersBloc saves and applies the reordered role list', () async {
    final repo = _RolesRepository();
    final key = EntityKey(entityId: 7, entityType: EntityType.server);
    repo.updateCache(key, const [
      RoleMember(id: 1, name: 'Первая', sortOrder: 0),
      RoleMember(id: 2, name: 'Вторая', sortOrder: 1),
    ]);
    final bus = WsEventBus();
    final bloc = RoleMembersBloc(
      repo,
      bus,
      entityId: 7,
      entityType: EntityType.server,
    );
    final reordered = bloc.stream.firstWhere(
      (state) =>
          state is RoleMembersLoaded &&
          !state.isSavingOrder &&
          state.roles.first.id == 2,
    );
    bloc.add(const ReorderRoleMembers([2, 1]));
    final state = await reordered as RoleMembersLoaded;
    expect(state.roles.map((role) => role.id), [2, 1]);
    expect(state.roles.map((role) => role.sortOrder), [0, 1]);
    await bloc.close();
    bus.dispose();
  });

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

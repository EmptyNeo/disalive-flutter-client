import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/invite_data.dart';
import 'package:disalive/domain/repositories/invite_repository.dart';
import 'package:disalive/presentation/features/invites/bloc/invites_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _InvitesRepository implements InviteRepository {
  final Map<int, List<InviteData>> cache = {};
  Completer<Either<Failure, List<InviteData>>>? listRequest;
  final Map<int, Completer<Either<Failure, List<InviteData>>>> serverRequests =
      {};
  final Map<String, Completer<Either<Failure, InviteDetails>>> lookups = {};
  Either<Failure, String> generateResult = const Right('Code1234');
  Either<Failure, bool> revokeResult = const Right(true);

  @override
  Future<Either<Failure, String>> generateCode() async => generateResult;

  @override
  Future<Either<Failure, InviteData>> create(
    int entityId,
    EntityType entityType,
    String code, {
    EntityKey? callEntity,
    int? targetChatId,
    int maxUsers = 0,
    int? expiresAt,
  }) async => Right(
    InviteData(
      id: 2,
      entityId: entityId,
      entityType: entityType.value,
      code: code,
    ),
  );

  @override
  Future<Either<Failure, InviteDetails>> getByCode(String code) =>
      lookups.putIfAbsent(code, Completer.new).future;

  @override
  Future<Either<Failure, InviteMembership>> checkMembership(
    String code,
  ) async => const Right(
    InviteMembership(
      isMember: false,
      entityId: 2,
      entityType: EntityType.server,
    ),
  );

  @override
  Future<Either<Failure, List<InviteData>>> getForServer(int serverId) async {
    final result = await (serverRequests[serverId] ?? listRequest!).future;
    result.fold((_) {}, (invites) => updateCache(serverId, invites));
    return result;
  }

  @override
  Future<Either<Failure, InviteAcceptance>> accept(String code) async =>
      const Right(InviteAcceptance(message: 'Joined'));

  @override
  Future<Either<Failure, bool>> revoke(int inviteId) async {
    revokeResult.fold((_) {}, (revoked) {
      if (!revoked) return;
      for (final invites in cache.values) {
        final index = invites.indexWhere((invite) => invite.id == inviteId);
        if (index >= 0) invites[index] = invites[index].copyWith(revoked: true);
      }
    });
    return revokeResult;
  }

  @override
  List<InviteData> getCached(int serverId) =>
      List.unmodifiable(cache[serverId] ?? const []);

  @override
  void updateCache(int serverId, List<InviteData> invites) {
    cache[serverId] = List.of(invites);
  }

  @override
  void clear([int? serverId]) {
    if (serverId == null) {
      cache.clear();
    } else {
      cache.remove(serverId);
    }
  }
}

Future<InvitesState> _until(
  InvitesBloc bloc,
  bool Function(InvitesState) matches,
) async {
  if (matches(bloc.state)) return bloc.state;
  return bloc.stream.firstWhere(matches).timeout(const Duration(seconds: 3));
}

void main() {
  test('shows cached invites and preserves them after load failure', () async {
    final repository = _InvitesRepository()
      ..updateCache(2, const [InviteData(id: 1, code: 'Old')])
      ..listRequest = Completer();
    final bloc = InvitesBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const LoadServerInvites(2));
    final loading = await _until(
      bloc,
      (state) => state.isPending(InviteOperation.load),
    );
    expect(loading.invites.single.code, 'Old');
    repository.listRequest!.complete(const Left(ServerFailure('Offline')));
    final failed = await _until(
      bloc,
      (state) => state.failureFor(InviteOperation.load) != null,
    );
    expect(failed.invites.single.code, 'Old');
    expect(failed.isPending(InviteOperation.load), isFalse);
  });

  test('create and revoke survive a pending server list response', () async {
    final repository = _InvitesRepository()
      ..updateCache(2, const [InviteData(id: 1, code: 'Old')])
      ..listRequest = Completer();
    final bloc = InvitesBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const LoadServerInvites(2));
    await _until(bloc, (state) => state.isPending(InviteOperation.load));
    bloc.add(
      const CreateInvite(
        entityId: 2,
        entityType: EntityType.server,
        code: 'New',
      ),
    );
    final created = await _until(
      bloc,
      (state) => state.lastCompleted == InviteOperation.create,
    );
    expect(created.invites.map((invite) => invite.id), [1, 2]);

    bloc.add(const RevokeInvite(1));
    final revoked = await _until(
      bloc,
      (state) => state.lastCompleted == InviteOperation.revoke,
    );
    expect(revoked.revokedId, 1);
    expect(revoked.invites.first.isRevoked, isTrue);

    repository.listRequest!.complete(
      const Right([InviteData(id: 1, code: 'Old', revoked: false)]),
    );
    final loaded = await _until(
      bloc,
      (state) => state.lastCompleted == InviteOperation.load,
    );
    expect(loaded.invites.map((invite) => invite.id), [1, 2]);
    expect(loaded.invites.first.isRevoked, isTrue);
    expect(repository.getCached(2), loaded.invites);
  });

  test('old server response does not replace the selected server', () async {
    final repository = _InvitesRepository()
      ..serverRequests[2] = Completer()
      ..serverRequests[3] = Completer();
    final bloc = InvitesBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const LoadServerInvites(2));
    await _until(
      bloc,
      (state) => state.serverId == 2 && state.isPending(InviteOperation.load),
    );
    bloc.add(const LoadServerInvites(3));
    await _until(
      bloc,
      (state) => state.serverId == 3 && state.isPending(InviteOperation.load),
    );
    repository.serverRequests[3]!.complete(
      const Right([InviteData(id: 3, code: 'Third')]),
    );
    await _until(bloc, (state) => state.lastCompleted == InviteOperation.load);
    repository.serverRequests[2]!.complete(
      const Right([InviteData(id: 2, code: 'Second')]),
    );
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.serverId, 3);
    expect(bloc.state.invites.single.code, 'Third');
  });

  test(
    'lookup ignores stale response; generation and accept expose results',
    () async {
      final repository = _InvitesRepository();
      final bloc = InvitesBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const GenerateInviteCode());
      final generated = await _until(
        bloc,
        (state) => state.lastCompleted == InviteOperation.generate,
      );
      expect(generated.generatedCode, 'Code1234');

      bloc.add(const LookupInvite('old'));
      await _until(bloc, (state) => state.isPending(InviteOperation.lookup));
      bloc.add(const LookupInvite('new'));
      await Future<void>.delayed(Duration.zero);
      repository.lookups['new']!.complete(
        const Right(InviteDetails(invite: InviteData(id: 3, code: 'new'))),
      );
      final found = await _until(
        bloc,
        (state) => state.lastCompleted == InviteOperation.lookup,
      );
      expect(found.details?.invite.code, 'new');
      repository.lookups['old']!.complete(
        const Right(InviteDetails(invite: InviteData(id: 4, code: 'old'))),
      );
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.details?.invite.code, 'new');

      bloc.add(const AcceptInvite('new'));
      final accepted = await _until(
        bloc,
        (state) => state.lastCompleted == InviteOperation.accept,
      );
      expect(accepted.acceptance?.message, 'Joined');
    },
  );
}

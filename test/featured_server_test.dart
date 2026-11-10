import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/presentation/features/profile/bloc/featured_server_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Servers implements ServerRepository {
  @override
  Future<Either<Failure, List<Server>>> getFeaturedServerChoices(
    int ownerId,
  ) async => const Right([
    Server(id: 4, fkOwner: 7, name: 'A', private: 0),
    Server(id: 1, fkOwner: 7, name: 'Z', private: 0),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Members implements MembersRepository {
  int? joinedId;

  @override
  Future<Either<Failure, Server>> create(
    int entityId,
    EntityType entityType,
  ) async {
    joinedId = entityId;
    expect(entityType, EntityType.server);
    return Right(Server(id: entityId, name: 'A', memberId: 17));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('parses featured server and sends zero when selection is cleared', () {
    final user = UserModel.fromMap({
      'id': 7,
      'featuredServerId': 4,
      'featuredServer': {
        'id': 4,
        'name': 'A',
        'pathAvatar': '/images/a.png',
        'memberId': null,
        'memberCount': 12,
      },
    });
    expect(user.featuredServer?.name, 'A');
    expect(user.featuredServer?.memberCount, 12);
    final cleared = user.copyWith(
      clearFeaturedServer: true,
      changeFeaturedServer: true,
    );
    expect(cleared.featuredServer, isNull);
    expect(cleared.toMap()['featuredServerId'], 0);
  });

  test('loads server choices and joins via members repository', () async {
    final members = _Members();
    final bloc = FeaturedServerBloc(_Servers(), members);
    bloc.add(const LoadFeaturedServerChoices(7));
    final loaded = await bloc.stream.firstWhere(
      (state) => !state.loading && state.choices.isNotEmpty,
    );
    expect(loaded.choices.map((server) => server.id), [4, 1]);
    bloc.add(const JoinFeaturedServer(4));
    final joined = await bloc.stream.firstWhere(
      (state) => state.joinedServer != null,
    );
    expect(joined.joinedServer?.memberId, 17);
    expect(members.joinedId, 4);
    await bloc.close();
  });
}

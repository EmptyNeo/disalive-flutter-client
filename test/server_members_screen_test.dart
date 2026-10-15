import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/server/server_members_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Members implements MembersRepository {
  int? entityId;
  EntityType? entityType;

  @override
  Future<List<Member>> getCached(EntityKey key) async => const [];

  @override
  Future<Either<Failure, List<Member>>> get(int id, EntityType type) async {
    entityId = id;
    entityType = type;
    return const Right([
      Member(fkUser: 8, user: UserModel(displayName: 'Алиса')),
    ]);
  }

  @override
  void clear() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('server members screen loads server participants', (
    tester,
  ) async {
    final repository = _Members();
    final bus = WsEventBus();
    final bloc = MembersBloc(repository, bus);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const CupertinoApp(
          home: ServerMembersScreen(server: Server(id: 2, name: 'Team')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.entityId, 2);
    expect(repository.entityType, EntityType.server);
    expect(find.text('Алиса'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await bloc.close();
      bus.dispose();
    });
  });
}

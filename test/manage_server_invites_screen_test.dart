import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/invite_data.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/invite_repository.dart';
import 'package:disalive/presentation/features/invites/bloc/invites_bloc.dart';
import 'package:disalive/presentation/features/invites/manage_server_invites_screen.dart';
import 'package:disalive/presentation/features/invites/widgets/server_invite_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Invites implements InviteRepository {
  int? loadedServerId;
  int? revokedId;
  List<InviteData> invites = const [
    InviteData(
      id: 7,
      entityId: 2,
      code: 'Ab12Cd34',
      currentCountInvite: 2,
      maxInvite: 5,
      user: UserModel(displayName: 'Алиса', username: 'alice'),
    ),
  ];

  @override
  Future<Either<Failure, List<InviteData>>> getForServer(int serverId) async {
    loadedServerId = serverId;
    return Right(invites);
  }

  @override
  Future<Either<Failure, bool>> revoke(int inviteId) async {
    revokedId = inviteId;
    return const Right(true);
  }

  @override
  List<InviteData> getCached(int serverId) => invites;

  @override
  void updateCache(int serverId, List<InviteData> updated) {
    invites = updated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('expiration label handles unlimited and a timestamp', () {
    expect(formatInviteExpiration(null), 'никогда');
    expect(formatInviteExpiration('0'), 'никогда');
    expect(
      formatInviteExpiration('2026-10-15 12:30:00'),
      contains('15.10.2026'),
    );
  });

  testWidgets('invite item displays author, usage and actions', (tester) async {
    var copies = 0;
    var revokes = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: ServerInviteItem(
            invite: const InviteData(
              id: 7,
              code: 'Ab12Cd34',
              currentCountInvite: 2,
              maxInvite: 5,
              user: UserModel(displayName: 'Алиса', username: 'alice'),
            ),
            onCopy: () => copies++,
            onRevoke: () => revokes++,
          ),
        ),
      ),
    );
    expect(find.text('Алиса'), findsOneWidget);
    expect(find.text('@alice'), findsOneWidget);
    expect(find.text('Код: Ab12Cd34'), findsOneWidget);
    expect(find.text('Использований: 2/5'), findsOneWidget);
    expect(find.text('Истекает: никогда'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('copy_invite_7')));
    await tester.tap(find.byKey(const ValueKey('revoke_invite_7')));
    expect(copies, 1);
    expect(revokes, 1);
  });

  testWidgets('management screen loads and revokes invite', (tester) async {
    final repository = _Invites();
    final bloc = InvitesBloc(repository);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const CupertinoApp(
          home: ManageServerInvitesScreen(server: Server(id: 2, name: 'Team')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.loadedServerId, 2);
    expect(find.text('Код: Ab12Cd34'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('revoke_invite_7')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отозвать'));
    await tester.pumpAndSettle();
    expect(repository.revokedId, 7);
    expect(repository.invites.single.isRevoked, isTrue);
    expect(find.text('Отозвано'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(bloc.close);
  });

  testWidgets('copy action places invite URL on clipboard', (tester) async {
    String? copied;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    final bloc = InvitesBloc(_Invites());
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const CupertinoApp(
          home: ManageServerInvitesScreen(server: Server(id: 2, name: 'Team')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('copy_invite_7')));
    await tester.pump();
    expect(copied, 'https://disalive.ru/invite/Ab12Cd34');
    await tester.pump(const Duration(seconds: 3));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(bloc.close);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });
}

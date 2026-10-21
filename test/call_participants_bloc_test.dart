import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/call_data.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/repositories/calls_repository.dart';
import 'package:disalive/presentation/features/calls/bloc/call_participants_bloc.dart';
import 'package:disalive/presentation/features/calls/widgets/call_activity_banner.dart';
import 'package:disalive/presentation/features/calls/widgets/channel_call_participants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

class _Calls implements CallsRepository {
  int requests = 0;
  int? lastChatId;

  @override
  Future<Either<Failure, CallParticipants>> getParticipants({
    required EntityKey entityKey,
    int? chatId,
  }) async {
    requests++;
    lastChatId = chatId;
    return const Right(
      CallParticipants({
        '12': [
          CallParticipant(
            identity: '8',
            name: 'Alex',
            metadata: {'displayName': 'Алекс'},
            tracks: [],
          ),
        ],
      }),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('polls every five seconds and stops when requested', (
    tester,
  ) async {
    final repository = _Calls();
    final bloc = CallParticipantsBloc(repository);
    addTearDown(bloc.close);
    bloc.add(
      const WatchCallParticipants(
        EntityKey(entityId: 12, entityType: EntityType.chat),
        chatId: 12,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(repository.requests, 1);
    expect(repository.lastChatId, 12);
    expect(bloc.state.hasParticipants(12), isTrue);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(repository.requests, 2);

    bloc.add(const StopWatchingCallParticipants());
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(repository.requests, 2);
    expect(bloc.state.hasParticipants(12), isFalse);
  });

  testWidgets('shows compact participants and lets the user collapse them', (
    tester,
  ) async {
    const participants = [
      CallParticipant(
        identity: '8',
        name: 'Alex',
        metadata: {'displayName': 'Алекс', 'deafened': true},
        tracks: [],
      ),
    ];
    var collapsed = false;
    await tester.pumpWidget(
      CupertinoApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              const CallActivityBanner(participantCount: 1),
              ChannelCallParticipants(
                participants: participants,
                isCollapsed: collapsed,
                onToggle: () => setState(() => collapsed = !collapsed),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('В звонке: 1'), findsOneWidget);
    expect(find.text('Алекс'), findsOneWidget);
    await tester.tap(find.text('В звонке · 1'));
    await tester.pump();
    expect(find.text('Алекс'), findsNothing);
  });
}

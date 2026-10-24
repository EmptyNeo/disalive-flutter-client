import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/calls_repository.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/chat_server_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/calls/bloc/call_bloc.dart';
import 'package:disalive/presentation/features/calls/incoming_call_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

class _Calls implements CallsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Socket implements ChatServerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Chats implements ChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Users implements UserRepository {
  @override
  UserModel? getCurrentUser() => const UserModel();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('incoming Call signal ignores self and can be declined', () async {
    final bus = WsEventBus();
    final bloc = CallBloc(_Calls(), _Socket(), bus, _Chats(), _Users())
      ..setupListeners();
    final data = <String, dynamic>{
      'nameAction': 'Call',
      'targetChatId': '42',
      'displayName': 'Алиса',
      'pathImage': '/avatar.png',
      'isNsfw': true,
      'streamType': 'audio',
    };
    bus.dispatch(
      WsEvent(
        table: 'Call',
        action: ActionType.create,
        data: data,
        isSelf: true,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.incomingCall, isNull);

    bus.dispatch(
      WsEvent(
        table: 'Call',
        action: ActionType.create,
        data: data,
        isSelf: false,
      ),
    );
    await bloc.stream.firstWhere((state) => state.incomingCall != null);
    expect(bloc.state.incomingCall?.chatId, 42);
    expect(bloc.state.incomingCall?.displayName, 'Алиса');
    expect(bloc.state.incomingCall?.isNsfw, isTrue);

    bloc.add(const DismissIncomingCall());
    await bloc.stream.firstWhere((state) => state.incomingCall == null);
    await bloc.close();
    bus.dispose();
  });

  testWidgets('incoming call dialog can be declined', (tester) async {
    bool? accepted;
    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoPageScaffold(
            child: Center(
              child: CupertinoButton(
                onPressed: () async {
                  accepted = await showIncomingCallDialog(
                    context,
                    const IncomingCall(chatId: 42, displayName: 'Алиса'),
                  );
                },
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    expect(find.text('Алиса'), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.phone_down_fill));
    await tester.pumpAndSettle();
    expect(accepted, isFalse);
  });
}

import 'dart:async';

import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/repositories/calls_repository.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/chat_server_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/calls/bloc/call_bloc.dart';
import 'package:disalive/presentation/features/calls/call_pip_overlay.dart';
import 'package:disalive/presentation/features/calls/call_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Calls implements CallsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Chats implements ChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ChatServer implements ChatServerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Users implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ConnectedCallBloc extends CallBloc {
  _ConnectedCallBloc(WsEventBus bus)
    : super(_Calls(), _ChatServer(), bus, _Chats(), _Users());

  void connectForTest() {
    emit(
      const CallState(
        status: CallStatus.connected,
        chatId: 1,
        entityKey: EntityKey(entityId: 1, entityType: EntityType.chat),
        title: 'Test call',
      ),
    );
  }
}

void main() {
  testWidgets('restores system bars before popping the call route', (
    tester,
  ) async {
    final restore = Completer<void>();
    final modes = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setEnabledSystemUIMode') {
        modes.add(call.arguments as String);
        if (call.arguments == 'SystemUiMode.edgeToEdge') {
          await restore.future;
        }
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final bus = WsEventBus();
    final bloc = CallBloc(_Calls(), _ChatServer(), bus, _Chats(), _Users());
    addTearDown(() async {
      await bloc.close();
      bus.dispose();
    });

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoPageScaffold(
            child: CupertinoButton(
              child: const Text('Open call'),
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: bloc,
                    child: const CallScreen(
                      chatId: 1,
                      entityKey: EntityKey(
                        entityId: 1,
                        entityType: EntityType.chat,
                      ),
                      title: 'Test call',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open call'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CallScreen), findsOneWidget);
    final exitRevision = CallScreen.exitRevision.value;

    await tester.tap(find.byIcon(CupertinoIcons.chevron_back));
    await tester.pump();
    expect(modes, contains('SystemUiMode.edgeToEdge'));
    expect(find.byType(CallScreen), findsOneWidget);

    restore.complete();
    for (
      var i = 0;
      i < 20 && find.byType(CallScreen).evaluate().isNotEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(CallScreen), findsNothing);
    expect(CallScreen.exitRevision.value, exitRevision + 1);
  });

  testWidgets('closes a call route without rebuilding PiP during unmount', (
    tester,
  ) async {
    final bus = WsEventBus();
    final bloc = _ConnectedCallBloc(bus)..connectForTest();
    addTearDown(() async {
      await bloc.close();
      bus.dispose();
    });

    await tester.pumpWidget(
      CupertinoApp(
        home: BlocProvider.value(
          value: bloc,
          child: Builder(
            builder: (context) => CupertinoPageScaffold(
              child: CupertinoButton(
                onPressed: () => CallScreen.open(
                  context,
                  chatId: 1,
                  callBloc: bloc,
                  entityKey: const EntityKey(
                    entityId: 1,
                    entityType: EntityType.chat,
                  ),
                  title: 'Test call',
                ),
                child: const Text('Open connected call'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open connected call'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    CallPipOverlay.setScreenVisible(false);
    await tester.pump();
    final callContext = tester.element(find.byType(CallScreen));
    Navigator.of(callContext).removeRoute(ModalRoute.of(callContext)!);
    await tester.pump();

    expect(find.byType(CallScreen), findsNothing);
    expect(tester.takeException(), isNull);
    CallPipOverlay.dispose();
    await tester.pump();
  });
}

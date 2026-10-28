import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/repositories/calls_repository.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/chat_server_repository.dart';
import 'package:disalive/domain/repositories/invite_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/calls/bloc/call_bloc.dart';
import 'package:disalive/presentation/features/calls/call_pip_overlay.dart';
import 'package:disalive/presentation/features/calls/call_screen.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/invites/bloc/invites_bloc.dart';
import 'package:disalive/presentation/features/invites/invite_server_screen.dart';
import 'package:disalive/presentation/features/message/bloc/message_bloc.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
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
  void clear() {}

  @override
  List<Chat> getCached() => const [
    Chat(id: 1, name: 'Group', type: ChatType.group, isCreator: true),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Servers implements ServerRepository {
  @override
  void clear() {}

  @override
  Server? getByIdCached(int id) => const Server(id: 1, isOwner: true);

  @override
  List<Server> getCached() => const [Server(id: 1, isOwner: true)];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Messages implements MessageRepository {
  @override
  void clearAllCache() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reactions implements ReactionsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Invites implements InviteRepository {
  @override
  Future<Either<Failure, String>> generateCode() async => const Right('Ab12');

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

  void connectForTest({EntityType entityType = EntityType.chat}) {
    emit(
      CallState(
        status: CallStatus.connected,
        chatId: 1,
        entityKey: EntityKey(entityId: 1, entityType: entityType),
        title: 'Test call',
      ),
    );
  }
}

void main() {
  for (final entityType in [EntityType.chat, EntityType.server]) {
    testWidgets('call route retains invitation BLoCs for $entityType', (
      tester,
    ) async {
      await sl.reset();
      final bus = WsEventBus();
      final chats = _Chats();
      final servers = _Servers();
      sl.registerSingleton<ChatRepository>(chats);
      sl.registerSingleton<ServerRepository>(servers);
      final callBloc = _ConnectedCallBloc(bus)
        ..connectForTest(entityType: entityType);
      final chatBloc = ChatBloc(chats, bus);
      final serversBloc = ServersBloc(servers, bus);
      final messageBloc = MessageBloc(_Messages(), _Reactions(), chats, bus);
      final invitesBloc = InvitesBloc(_Invites());

      await tester.pumpWidget(
        CupertinoApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<CallBloc>.value(value: callBloc),
              BlocProvider.value(value: chatBloc),
              BlocProvider.value(value: serversBloc),
              BlocProvider.value(value: messageBloc),
              BlocProvider.value(value: invitesBloc),
            ],
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () => CallScreen.open(
                  context,
                  chatId: 1,
                  entityKey: EntityKey(entityId: 1, entityType: entityType),
                  title: 'Group',
                ),
                child: const Text('Open call with providers'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open call with providers'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final callContext = tester.element(find.byType(CallScreen));
      expect(callContext.read<ChatBloc>(), same(chatBloc));
      expect(callContext.read<ServersBloc>(), same(serversBloc));
      expect(callContext.read<MessageBloc>(), same(messageBloc));
      expect(callContext.read<InvitesBloc>(), same(invitesBloc));
      expect(find.byKey(const ValueKey('invite_to_call')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('invite_to_call')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(InviteServerScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      CallPipOverlay.dispose();
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await callBloc.close();
        await chatBloc.close();
        await serversBloc.close();
        await messageBloc.close();
        await invitesBloc.close();
        bus.dispose();
        await sl.reset();
      });
    });
  }

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

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/invite_data.dart';
import 'package:disalive/domain/models/link_data.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/features/message/message_item.dart';
import 'package:disalive/presentation/features/message/widgets/invite_message_card.dart';
import 'package:disalive/presentation/features/message/widgets/link_preview.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _ServerRepository implements ServerRepository {
  _ServerRepository([List<Server> servers = const []]) : _servers = servers;

  List<Server> _servers;
  int? _selectedServerId;

  @override
  int? get selectedServerId => _selectedServerId;

  @override
  Server? get selectedServer =>
      _servers.where((server) => server.id == _selectedServerId).firstOrNull;

  @override
  void selectServer(int? serverId) => _selectedServerId = serverId;

  @override
  List<Server> getCached() => _servers;

  @override
  Future<Either<Failure, List<Server>>> get() async => Right(_servers);

  @override
  void updateCache(List<Server> servers) => _servers = servers;

  @override
  void clear() => _selectedServerId = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('message renders invite card in place of link preview', (
    tester,
  ) async {
    final bus = WsEventBus();
    final serversBloc = ServersBloc(_ServerRepository(), bus);
    await tester.pumpWidget(
      BlocProvider.value(
        value: serversBloc,
        child: CupertinoApp(
          home: Center(
            child: MessageItem(
              message: const Message(
                text: 'https://disalive.ru/invite/Ab12',
                inviteData: InviteData(
                  entityId: 5,
                  name: 'Сообщество',
                  memberCount: 8,
                  onlineMemberCount: 2,
                ),
                linkPreview: LinkData(title: 'Обычное превью'),
              ),
              isMine: false,
              isRead: true,
              showTime: false,
              onStickerTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(InviteMessageCard), findsOneWidget);
    expect(find.byType(LinkPreview), findsNothing);
    expect(find.text('Сообщество'), findsOneWidget);
    expect(find.text('2 в сети'), findsOneWidget);
    expect(find.text('8 участников'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await serversBloc.close();
      bus.dispose();
    });
  });

  testWidgets('message without invite link does not render the card', (
    tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: MessageItem(
            message: const Message(
              text: 'No link',
              inviteData: InviteData(name: 'Сообщество'),
              linkPreview: LinkData(title: 'Обычное превью'),
            ),
            isMine: false,
            isRead: true,
            showTime: false,
            onStickerTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(InviteMessageCard), findsNothing);
    expect(find.byType(LinkPreview), findsNothing);
  });

  testWidgets('revoked invitation offers to request a new link', (
    tester,
  ) async {
    String? request;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: InviteMessageCard(
            invite: const InviteData(name: 'Команда', revoked: true),
            code: 'Ab12',
            onMention: (value) => request = value,
          ),
        ),
      ),
    );

    expect(find.textContaining('отозвано'), findsOneWidget);
    expect(find.text('Присоединиться'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('invite_card_mention')));
    expect(request, contains('сервер Команда'));
  });

  testWidgets('server ID in invite data opens an existing server', (
    tester,
  ) async {
    final bus = WsEventBus();
    final serversBloc = ServersBloc(
      _ServerRepository([const Server(id: 42, name: 'Сообщество')]),
      bus,
    );
    serversBloc.add(const GetServers());
    await tester.pumpWidget(
      BlocProvider.value(
        value: serversBloc,
        child: const CupertinoApp(
          home: Center(
            child: InviteMessageCard(
              invite: InviteData(id: 42, name: 'Сообщество'),
              code: 'Ab12',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Перейти на сервер'), findsOneWidget);
    expect(find.text('Присоединиться'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('invite_card_action')));
    await tester.pump();
    expect((serversBloc.state as ServersLoaded).selectedServerId, 42);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await serversBloc.close();
      bus.dispose();
    });
  });
}

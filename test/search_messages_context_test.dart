import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/responses/message_response.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/presentation/features/chat/screens/search_messages_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

class _ChatRepository implements ChatRepository {
  _ChatRepository(this.current);

  final Chat current;

  @override
  Chat? getCurrentChat() => current;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ServerRepository implements ServerRepository {
  _ServerRepository(this.selectedServerId);

  @override
  final int? selectedServerId;

  @override
  Server? get selectedServer => selectedServerId == null
      ? null
      : Server(id: selectedServerId, name: 'Сервер');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MessageRepository implements MessageRepository {
  int? chatId;
  int? entityId;
  EntityType? entityType;
  String? searchQuery;

  @override
  Future<Either<Failure, MessagesResponse>> get(
    int chatId,
    int entityId,
    EntityType entityType,
    int limit,
    int lastIdMessage,
    int? aroundId,
    int? newerThanId,
    String? searchQuery,
  ) async {
    this.chatId = chatId;
    this.entityId = entityId;
    this.entityType = entityType;
    this.searchQuery = searchQuery;
    return const Right(MessagesResponse(messages: [], actions: []));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => sl.reset());

  testWidgets('search uses the open channel and selected server', (
    tester,
  ) async {
    const openChannel = Chat(id: 70, name: 'Канал', type: ChatType.channel);
    final messages = _MessageRepository();
    sl.registerSingleton<ChatRepository>(_ChatRepository(openChannel));
    sl.registerSingleton<ServerRepository>(_ServerRepository(12));
    sl.registerSingleton<MessageRepository>(messages);

    await tester.pumpWidget(
      CupertinoApp(
        home: SearchMessagesScreen(
          chat: const Chat(id: 5, name: 'Устаревший чат'),
          onStickerTap: (_) {},
        ),
      ),
    );
    await tester.enterText(find.byType(CupertinoTextField), 'привет');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(messages.chatId, 70);
    expect(messages.entityId, 12);
    expect(messages.entityType, EntityType.server);
    expect(messages.searchQuery, 'привет');
  });

  testWidgets('search in a regular chat uses chat context', (tester) async {
    const chat = Chat(id: 28, name: 'Группа', type: ChatType.group);
    final messages = _MessageRepository();
    sl.registerSingleton<ChatRepository>(_ChatRepository(chat));
    sl.registerSingleton<ServerRepository>(_ServerRepository(null));
    sl.registerSingleton<MessageRepository>(messages);

    await tester.pumpWidget(
      CupertinoApp(
        home: SearchMessagesScreen(chat: chat, onStickerTap: (_) {}),
      ),
    );
    await tester.enterText(find.byType(CupertinoTextField), 'тест');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(messages.chatId, 28);
    expect(messages.entityId, 28);
    expect(messages.entityType, EntityType.chat);
  });
}

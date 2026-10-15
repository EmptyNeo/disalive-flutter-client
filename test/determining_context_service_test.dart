import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/determining_context_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _ChatRepository implements ChatRepository {
  _ChatRepository(this.currentChat);

  final Chat? currentChat;

  @override
  Chat? getCurrentChat() => currentChat;

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
      : Server(id: selectedServerId, name: 'Selected');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => sl.reset());

  test('selected server takes priority over the current chat', () {
    sl.registerSingleton<ChatRepository>(
      _ChatRepository(const Chat(id: 12, name: 'Chat')),
    );
    sl.registerSingleton<ServerRepository>(_ServerRepository(42));

    expect(
      DeterminingContextService.getEntityKey(),
      const EntityKey(entityId: 42, entityType: EntityType.server),
    );
  });

  test('current chat is used when no server is selected', () {
    sl.registerSingleton<ChatRepository>(
      _ChatRepository(const Chat(id: 12, name: 'Chat')),
    );
    sl.registerSingleton<ServerRepository>(_ServerRepository(null));

    expect(
      DeterminingContextService.getEntityKey(),
      const EntityKey(entityId: 12, entityType: EntityType.chat),
    );
  });

  test('returns null when neither server nor chat is available', () {
    sl.registerSingleton<ChatRepository>(_ChatRepository(null));

    expect(DeterminingContextService.getEntityKey(), isNull);
  });
}

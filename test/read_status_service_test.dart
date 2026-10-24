import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/read_status_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _Members implements MembersRepository {
  final updates = <(int, EntityType, int?, int?)>[];

  @override
  Future<Either<Failure, bool>> update({
    required int entityId,
    required EntityType entityType,
    int? chatId,
    int? lastIdReadMessage,
    bool toggleMuted = false,
    bool toggleFixed = false,
  }) async {
    updates.add((entityId, entityType, chatId, lastIdReadMessage));
    return const Right(true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Channels implements ChannelServerRepository {
  _Channels(this.items);
  final List<ChannelServer> items;

  @override
  Future<Either<Failure, List<ChannelServer>>> get(int serverId) async =>
      Right(items);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Http extends HttpClientService {
  _Http(this.latestByChat) : super(secureStorage: SecureStorageService());
  final Map<int, int> latestByChat;
  final queriedChats = <int>[];

  @override
  Future<Either<Failure, T>> postFormData<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    required T Function(dynamic json) fromJson,
    ApiType apiType = ApiType.v1,
    bool requireAuth = true,
    String? errorMessage,
    VoidCallback? onUnauthorized,
  }) async {
    expect(endpoint, 'messages/get.php');
    expect(data?['limit'], 1);
    final chatId = data!['chatId'] as int;
    queriedChats.add(chatId);
    final id = latestByChat[chatId];
    return Right(
      fromJson({
        'messages': id == null
            ? []
            : [
                {'id': id},
              ],
      }),
    );
  }
}

void main() {
  test('marks one chat at its last message', () async {
    final members = _Members();
    final service = ReadStatusService(members, _Channels([]), _Http({}));

    final result = await service.markChat(
      const Chat(id: 7, name: 'Чат', idLastMessage: 42, newMessagesCount: 3),
    );

    expect(result.getOrElse(() => null), 42);
    expect(members.updates, [(7, EntityType.chat, 7, 42)]);
  });

  test('fetches the latest message when a chat has no last ID', () async {
    final members = _Members();
    final http = _Http({7: 44});
    final service = ReadStatusService(members, _Channels([]), http);

    final result = await service.markChat(
      const Chat(id: 7, name: 'Чат', newMessagesCount: 2),
    );

    expect(result.getOrElse(() => null), 44);
    expect(http.queriedChats, [7]);
    expect(members.updates, [(7, EntityType.chat, 7, 44)]);
  });

  test('marks each unread server channel with its own chat ID', () async {
    final members = _Members();
    final http = _Http({11: 70, 12: 95});
    final service = ReadStatusService(
      members,
      _Channels(const [
        ChannelServer(chatId: 11, newMessagesCount: 2, lastIdReadMessage: 50),
        ChannelServer(chatId: 12, newMessagesCount: 1, lastIdReadMessage: 50),
        ChannelServer(chatId: 13, newMessagesCount: 0, lastIdReadMessage: 50),
      ]),
      http,
    );

    final result = await service.markServer(
      const Server(id: 3, newMessagesCount: 3),
    );

    expect(result.getOrElse(() => false), isTrue);
    expect(http.queriedChats, [11, 12]);
    expect(members.updates, [
      (3, EntityType.server, 11, 70),
      (3, EntityType.server, 12, 95),
    ]);
  });

  test('marks one channel using its latest message', () async {
    final members = _Members();
    final http = _Http({11: 70});
    final service = ReadStatusService(members, _Channels([]), http);

    final result = await service.markChannel(
      3,
      const ChannelServer(
        chatId: 11,
        newMessagesCount: 2,
        lastIdReadMessage: 50,
      ),
    );

    expect(result.getOrElse(() => false), isTrue);
    expect(http.queriedChats, [11]);
    expect(members.updates, [(3, EntityType.server, 11, 70)]);
  });
}

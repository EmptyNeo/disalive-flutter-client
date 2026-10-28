import 'dart:convert';

import 'package:disalive/data/repositories/invite_repository_impl.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/invite_data.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _TestStorage extends SecureStorageService {
  @override
  Future<String?> getKeySession() async => 'session-key';
}

http.Response _ok(dynamic data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('invite model keeps existing preview fields and builds HTTPS link', () {
    final invite = InviteData.fromMap({
      'id': '4',
      'entityId': '2',
      'entityType': 'server',
      'code': 'A B/1',
      'name': 'Team',
      'memberCount': '12',
      'revoked': 0,
      'maxInvite': '20',
      'callEntity': {'id': '9', 'type': 'chat'},
      'targetChatId': '91',
      'targetChatName': 'Голосовой канал',
    });
    expect(invite.id, 4);
    expect(invite.entityId, 2);
    expect(invite.memberCount, 12);
    expect(invite.maxInvite, 20);
    expect(invite.targetChatId, 91);
    expect(invite.targetChatName, 'Голосовой канал');
    expect(invite.isRevoked, isFalse);
    expect(
      invite.callEntity,
      const EntityKey(entityId: 9, entityType: EntityType.chat),
    );
    expect(invite.inviteUrl, 'https://disalive.ru/invite/A%20B%2F1');
    expect(InviteData.fromMap(invite.toMap()), invite);
    expect(
      InviteData.fromMap({
        'callEntity': {'entityId': 9, 'entityType': 'chat'},
      }).callEntity,
      invite.callEntity,
    );
  });

  test('generate, create, public lookup and accept use API contract', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      switch (request.url.path) {
        case '/v1/invites/generate.php':
          return _ok('Ab12Cd34');
        case '/v1/invites/create.php':
          return _ok({
            'id': 5,
            'entityId': 2,
            'entityType': 'server',
            'code': 'Ab12Cd34',
            'maxInvite': 10,
          });
        case '/v1/invites/get.php':
          if (request.method == 'POST') {
            return _ok({
              'isMember': true,
              'entityId': 2,
              'entityType': 'server',
              'targetChatId': 91,
            });
          }
          return _ok({
            'invite': {
              'id': 5,
              'code': 'Ab12Cd34',
              'entityId': 2,
              'targetChatId': 91,
            },
            'server': {'id': 2, 'name': 'Team'},
            'targetChatName': 'Голосовой канал',
          });
        case '/v1/invites/accept.php':
          return _ok({
            'message': 'Successfully joined server',
            'server': {'id': 2, 'name': 'Team'},
            'entityId': 2,
            'entityType': 'server',
            'targetChatId': 91,
          });
        default:
          throw StateError('Unexpected path: ${request.url.path}');
      }
    });
    final httpClient = HttpClientService(
      client: client,
      secureStorage: _TestStorage(),
    );
    addTearDown(httpClient.dispose);
    final repository = InviteRepositoryImpl(httpClient: httpClient);

    final generated = await repository.generateCode();
    expect(generated.getOrElse(() => ''), 'Ab12Cd34');
    expect(requests[0].method, 'GET');
    expect(requests[0].url.queryParameters['keySession'], 'session-key');

    final created = await repository.create(
      2,
      EntityType.server,
      'Ab12Cd34',
      callEntity: const EntityKey(entityId: 9, entityType: EntityType.chat),
      targetChatId: 91,
      maxUsers: 10,
      expiresAt: 1800,
    );
    expect(created.isRight(), isTrue);
    expect(
      created.getOrElse(() => const InviteData()).inviteUrl,
      'https://disalive.ru/invite/Ab12Cd34',
    );
    expect(requests[1].method, 'POST');
    expect(requests[1].bodyFields, containsPair('entityId', '2'));
    expect(requests[1].bodyFields, containsPair('entityType', 'server'));
    expect(requests[1].bodyFields, containsPair('code', 'Ab12Cd34'));
    expect(requests[1].bodyFields, containsPair('maxUsers', '10'));
    expect(requests[1].bodyFields, containsPair('expiresAt', '1800'));
    expect(requests[1].bodyFields, containsPair('callEntity[id]', '9'));
    expect(requests[1].bodyFields, containsPair('callEntity[type]', 'chat'));
    expect(requests[1].bodyFields, containsPair('targetChatId', '91'));

    final details = await repository.getByCode('Ab12Cd34');
    expect(details.isRight(), isTrue);
    expect(
      details.getOrElse(() => throw StateError('No details')).server?.name,
      'Team',
    );
    expect(requests[2].method, 'GET');
    expect(requests[2].url.queryParameters['code'], 'Ab12Cd34');
    expect(requests[2].url.queryParameters.containsKey('keySession'), isFalse);
    expect(
      details.getOrElse(() => throw StateError('No details')).targetChatName,
      'Голосовой канал',
    );

    final membership = await repository.checkMembership('Ab12Cd34');
    expect(membership.isRight(), isTrue);
    expect(
      membership.getOrElse(() => throw StateError('No membership')).isMember,
      isTrue,
    );
    expect(
      membership
          .getOrElse(() => throw StateError('No membership'))
          .targetChatId,
      91,
    );
    expect(requests[3].method, 'POST');
    expect(requests[3].bodyFields, containsPair('code', 'Ab12Cd34'));
    expect(requests[3].bodyFields, containsPair('keySession', 'session-key'));

    final accepted = await repository.accept('Ab12Cd34');
    expect(accepted.isRight(), isTrue);
    expect(accepted.getOrElse(() => const InviteAcceptance()).server?.id, 2);
    expect(accepted.getOrElse(() => const InviteAcceptance()).targetChatId, 91);
    expect(requests[4].method, 'POST');
    expect(requests[4].bodyFields, containsPair('code', 'Ab12Cd34'));
    expect(requests[4].bodyFields, containsPair('keySession', 'session-key'));
  });

  test('group invitation parses chat and joined conversation', () {
    final details = InviteDetails.fromMap({
      'invite': {'id': 12, 'entityId': 7, 'entityType': 'chat'},
      'chat': {'chatId': 7, 'name': 'Группа'},
    });
    expect(details.chat?.id, 7);
    expect(details.chat?.name, 'Группа');

    final acceptance = InviteAcceptance.fromMap({
      'entityId': 7,
      'entityType': 'chat',
      'alreadyMember': false,
      'conversation': {'chatId': 7, 'name': 'Группа'},
    });
    expect(acceptance.conversation?.id, 7);
    expect(acceptance.entityType, EntityType.chat);
  });

  test(
    'server list uses POST query, survives error and revoke updates cache',
    () async {
      var listCalls = 0;
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/get.php')) {
          listCalls++;
          if (listCalls == 1) {
            return _ok([
              {'id': 5, 'entityId': 2, 'code': 'Ab12Cd34', 'revoked': 0},
            ]);
          }
          return http.Response(
            jsonEncode({'success': false, 'error': 'Temporary error'}),
            500,
          );
        }
        if (request.url.path.endsWith('/revoke.php')) return _ok(null);
        throw StateError('Unexpected path: ${request.url.path}');
      });
      final httpClient = HttpClientService(
        client: client,
        secureStorage: _TestStorage(),
      );
      addTearDown(httpClient.dispose);
      final repository = InviteRepositoryImpl(httpClient: httpClient);

      expect((await repository.getForServer(2)).isRight(), isTrue);
      expect(requests[0].method, 'POST');
      expect(requests[0].url.path, '/v1/invites/get.php');
      expect(requests[0].url.queryParameters['entityId'], '2');
      expect(requests[0].bodyFields, containsPair('keySession', 'session-key'));
      expect(repository.getCached(2), hasLength(1));

      expect((await repository.getForServer(2)).isLeft(), isTrue);
      expect(repository.getCached(2), hasLength(1));

      expect((await repository.revoke(5)).getOrElse(() => false), isTrue);
      expect(requests[2].method, 'POST');
      expect(requests[2].bodyFields, containsPair('id', '5'));
      expect(repository.getCached(2).single.isRevoked, isTrue);
      repository.clear(2);
      expect(repository.getCached(2), isEmpty);
    },
  );
}

import 'dart:convert';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/data/repositories/role_member_repository_impl.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _TestStorage extends SecureStorageService {
  @override
  Future<String?> getKeySession() async => 'session-key';
}

http.Response _ok(dynamic data) => http.Response.bytes(
  utf8.encode(jsonEncode({'success': true, 'data': data})),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  setUp(() async => sl.reset());
  tearDown(() async {
    if (sl.isRegistered<HttpClientService>()) {
      sl<HttpClientService>().dispose();
    }
    await sl.reset();
  });

  test('role can have only a name or only an emoji', () {
    final named = RoleMember.fromMap({
      'id': 1,
      'name': 'Moderator',
      'emoji': null,
      'permissions': {'manageRoles': 1},
    });
    final emoji = RoleMember.fromMap({
      'id': 2,
      'name': null,
      'emoji': '⭐',
      'permissions': {'manageRoles': false},
    });
    expect(named.name, 'Moderator');
    expect(named.emoji, isNull);
    expect(named.hasPermission('manageRoles'), isTrue);
    expect(emoji.name, isNull);
    expect(emoji.emoji, '⭐');
    expect(emoji.hasPermission('manageRoles'), isFalse);
  });

  test('loads roles by entity and keeps cache after failure', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      expect(request.method, 'POST');
      expect(request.url.path, '/v1/roleMembers/get.php');
      expect(request.bodyFields['keySession'], 'session-key');
      expect(request.bodyFields['entityId'], '2');
      expect(request.bodyFields['entityType'], 'server');
      if (calls == 1) {
        return _ok([
          {
            'id': 5,
            'entityId': 2,
            'entityType': 'server',
            'name': 'Moderator',
            'permissions': {'manageRoles': true},
          },
        ]);
      }
      return http.Response(
        jsonEncode({'success': false, 'error': 'Temporary error'}),
        500,
      );
    });
    sl.registerSingleton<HttpClientService>(
      HttpClientService(client: client, secureStorage: _TestStorage()),
    );
    final repository = RoleMemberRepositoryImpl();
    const serverKey = EntityKey(entityId: 2, entityType: EntityType.server);
    const chatKey = EntityKey(entityId: 2, entityType: EntityType.chat);

    expect((await repository.get(2, EntityType.server)).isRight(), isTrue);
    expect(repository.getCached(serverKey), hasLength(1));
    expect(repository.getCached(chatKey), isEmpty);
    expect(repository.getByIdCached(5)?.name, 'Moderator');

    expect((await repository.get(2, EntityType.server)).isLeft(), isTrue);
    expect(repository.getCached(serverKey), hasLength(1));
    repository.clear(serverKey);
    expect(repository.getByIdCached(5), isNull);
  });

  test(
    'create, emoji-only update, delete and assignments use API fields',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        expect(request.method, 'POST');
        expect(request.bodyFields['keySession'], 'session-key');
        if (path.endsWith('/get.php')) {
          return _ok([
            {
              'id': 5,
              'entityId': 2,
              'entityType': 'server',
              'name': 'Moderator',
              'permissions': {'manageRoles': false},
            },
          ]);
        }
        if (path.endsWith('/create.php')) {
          return _ok({
            'id': 6,
            'entityId': 2,
            'entityType': 'server',
            'name': 'Новая роль',
            'emoji': null,
            'permissions': {'manageRoles': false},
          });
        }
        if (path.endsWith('/update.php')) {
          return _ok({
            'id': 6,
            'name': null,
            'emoji': '⭐',
            'permissions': {'manageRoles': true},
          });
        }
        return _ok(null);
      });
      sl.registerSingleton<HttpClientService>(
        HttpClientService(client: client, secureStorage: _TestStorage()),
      );
      final repository = RoleMemberRepositoryImpl();
      const key = EntityKey(entityId: 2, entityType: EntityType.server);

      await repository.get(2, EntityType.server);
      final created = await repository.create(2, EntityType.server);
      expect(created.isRight(), isTrue, reason: created.toString());
      expect(requests[1].url.path, '/v1/roleMembers/create.php');
      expect(requests[1].bodyFields.containsKey('name'), isFalse);
      expect(repository.getCached(key), hasLength(2));

      final updated = await repository.update(
        6,
        2,
        EntityType.server,
        emoji: '⭐',
        permissions: {'manageRoles': true},
      );
      expect(updated.isRight(), isTrue);
      expect(requests[2].url.path, '/v1/roleMembers/update.php');
      expect(requests[2].bodyFields.containsKey('name'), isFalse);
      expect(requests[2].bodyFields['emoji'], '⭐');
      expect(
        jsonDecode(requests[2].bodyFields['permissions']!)['manageRoles'],
        true,
      );
      expect(repository.getByIdCached(6)?.name, isNull);
      expect(repository.getByIdCached(6)?.emoji, '⭐');

      expect(
        (await repository.assign(6, 2, EntityType.server, [8, 9])).isRight(),
        isTrue,
      );
      expect(requests[3].url.path, '/v1/roleMembers/assign.php');
      expect(jsonDecode(requests[3].bodyFields['userIds']!), [8, 9]);
      expect(requests[3].bodyFields['roleId'], '6');

      expect(
        (await repository.unassign(6, 2, EntityType.server, 8)).isRight(),
        isTrue,
      );
      expect(requests[4].url.path, '/v1/roleMembers/unassign.php');
      expect(requests[4].bodyFields['userId'], '8');

      expect(
        (await repository.delete(6, 2, EntityType.server)).isRight(),
        isTrue,
      );
      expect(requests[5].url.path, '/v1/roleMembers/delete.php');
      expect(repository.getByIdCached(6), isNull);
      expect(repository.getCached(key), hasLength(1));
    },
  );
}

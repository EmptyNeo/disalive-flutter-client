import 'dart:convert';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/data/repositories/category_channel_repository_impl.dart';
import 'package:disalive/data/repositories/channel_server_repository_impl.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _TestStorage extends SecureStorageService {
  @override
  Future<String?> getKeySession() async => 'session-key';
}

http.Response _ok(dynamic data) =>
    http.Response(jsonEncode({'success': true, 'data': data}), 200);

void main() {
  setUp(() async => sl.reset());
  tearDown(() async {
    if (sl.isRegistered<HttpClientService>()) {
      sl<HttpClientService>().dispose();
    }
    await sl.reset();
  });

  test('channel requests, model fields and cache changes', () async {
    final sent = <http.Request>[];
    final client = MockClient((request) async {
      sent.add(request);
      expect(request.url.path, startsWith('/v1/channelsServer/'));
      if (request.url.path.endsWith('/get.php')) {
        if (request.url.queryParameters.containsKey('id')) {
          return _ok({
            'id': 10,
            'serverId': 2,
            'chatId': 90,
            'type': 'text',
            'categoryId': null,
            'isPrivate': true,
            'chatName': 'General',
            'newMessagesCount': 3,
            'lastIdReadMessage': 40,
            'allowedUsers': [1],
            'allowedRoles': [5],
          });
        }
        return _ok([
          {
            'id': 10,
            'serverId': 2,
            'chatId': 90,
            'type': 'text',
            'categoryId': null,
            'isPrivate': true,
            'chatName': 'General',
            'newMessagesCount': 3,
            'lastIdReadMessage': 40,
            'allowedUsers': [1],
            'allowedRoles': [5],
          },
        ]);
      }
      if (request.url.path.endsWith('/create.php')) {
        return _ok({
          'id': 11,
          'serverId': 2,
          'chatId': 91,
          'type': 'text',
          'categoryId': 7,
          'isPrivate': true,
          'chatName': 'Private',
          'allowedUsers': [1, 3],
          'allowedRoles': [5],
        });
      }
      if (request.url.path.endsWith('/update.php')) {
        return _ok({
          'id': 10,
          'serverId': 2,
          'chatId': 90,
          'type': 'text',
          'categoryId': null,
          'isPrivate': true,
          'chatName': 'Renamed',
        });
      }
      return _ok({'id': 11});
    });
    sl.registerSingleton<HttpClientService>(
      HttpClientService(client: client, secureStorage: _TestStorage()),
    );
    final repository = ChannelServerRepositoryImpl();

    expect((await repository.get(2)).isRight(), isTrue);
    expect(sent[0].method, 'GET');
    expect(sent[0].url.queryParameters['serverId'], '2');
    expect(sent[0].url.queryParameters['keySession'], 'session-key');
    expect(repository.getByIdCached(10)?.newMessagesCount, 3);
    expect(repository.getByIdCached(10)?.allowedRoles, [5]);
    expect(repository.getByIdCached(10)?.toMap()['isPrivate'], true);

    expect((await repository.getById(10)).isRight(), isTrue);
    expect(sent[1].url.queryParameters['id'], '10');
    expect(repository.getCached(2), hasLength(1));

    expect(
      (await repository.create(
        2,
        'Private',
        categoryId: 7,
        isPrivate: true,
        userIds: [3, 4],
        roleIds: [5],
      )).isRight(),
      isTrue,
    );
    expect(sent[2].bodyFields, containsPair('entityId', '2'));
    expect(sent[2].bodyFields, containsPair('entityType', 'server'));
    expect(sent[2].bodyFields, containsPair('isPrivate', '1'));
    expect(sent[2].bodyFields, containsPair('userIds[0]', '3'));
    expect(sent[2].bodyFields, containsPair('userIds[1]', '4'));
    expect(sent[2].bodyFields, containsPair('roleIds[0]', '5'));
    expect(repository.getCached(2), hasLength(2));

    expect(
      (await repository.update(10, name: 'Renamed', categoryId: 0)).isRight(),
      isTrue,
    );
    expect(sent[3].bodyFields, containsPair('categoryId', '0'));
    expect(repository.getByIdCached(10)?.categoryId, isNull);
    expect(repository.getByIdCached(10)?.newMessagesCount, 3);
    expect(repository.getByIdCached(10)?.chatName, 'Renamed');

    expect((await repository.delete(11)).isRight(), isTrue);
    expect(repository.getByIdCached(11), isNull);
    repository.clear(2);
    expect(repository.getCached(2), isEmpty);
  });

  test(
    'category list accepts raw PHP objects and synchronizes cache',
    () async {
      final sent = <http.Request>[];
      final client = MockClient((request) async {
        sent.add(request);
        expect(request.url.path, startsWith('/v1/categories/'));
        if (request.url.path.endsWith('/get.php')) {
          return _ok([
            {'id': 7, 'fkServer': 2, 'name': 'Text'},
          ]);
        }
        if (request.url.path.endsWith('/create.php')) {
          return _ok({'id': 8, 'serverId': 2, 'name': 'Voice'});
        }
        if (request.url.path.endsWith('/update.php')) {
          return _ok({'id': 7, 'serverId': 2, 'name': 'News'});
        }
        return _ok(null);
      });
      sl.registerSingleton<HttpClientService>(
        HttpClientService(client: client, secureStorage: _TestStorage()),
      );
      final repository = CategoryChannelRepositoryImpl();

      expect((await repository.get(2)).isRight(), isTrue);
      expect(sent[0].method, 'POST');
      expect(sent[0].url.queryParameters['serverId'], '2');
      expect(sent[0].bodyFields['keySession'], 'session-key');
      expect(repository.getByIdCached(7)?.serverId, 2);
      expect(repository.getByIdCached(7)?.toMap()['serverId'], 2);

      expect((await repository.create(2, 'Voice')).isRight(), isTrue);
      expect(sent[1].bodyFields, containsPair('serverId', '2'));
      expect(repository.getCached(2), hasLength(2));

      expect((await repository.update(7, 'News')).isRight(), isTrue);
      expect(repository.getByIdCached(7)?.name, 'News');

      expect((await repository.delete(8)).isRight(), isTrue);
      expect(repository.getByIdCached(8), isNull);
      repository.clear();
      expect(repository.getCached(2), isEmpty);
    },
  );

  test('failed channel and category requests retain loaded cache', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls <= 2) {
        return _ok(
          request.url.path.contains('channelsServer')
              ? [
                  {'id': 1, 'serverId': 2},
                ]
              : [
                  {'id': 3, 'serverId': 2},
                ],
        );
      }
      return http.Response(
        jsonEncode({'success': false, 'error': 'Temporary error'}),
        500,
      );
    });
    sl.registerSingleton<HttpClientService>(
      HttpClientService(client: client, secureStorage: _TestStorage()),
    );
    final channels = ChannelServerRepositoryImpl();
    final categories = CategoryChannelRepositoryImpl();
    await channels.get(2);
    await categories.get(2);
    expect((await channels.get(2)).isLeft(), isTrue);
    expect((await categories.get(2)).isLeft(), isTrue);
    expect(channels.getCached(2), hasLength(1));
    expect(categories.getCached(2), hasLength(1));
  });
}

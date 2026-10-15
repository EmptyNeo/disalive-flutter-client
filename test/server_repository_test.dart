import 'dart:convert';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/data/repositories/server_repository_impl.dart';
import 'package:disalive/domain/enums/server_type.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _TestStorage extends SecureStorageService {
  @override
  Future<String?> getKeySession() async => 'session-key';
}

void main() {
  test('server categories use API values and Russian labels', () {
    expect(ServerType.values.map((type) => type.value).toList(), [
      'NONE',
      'GAMES',
      'MUSIC',
      'ENTERTAINMENT',
      'SCIENCE_AND_TECHNOLOGY',
      'EDUCATION',
      'SPORTS',
    ]);
    expect(ServerType.scienceAndTechnology.label, 'Наука и технологии');
    expect(ServerType.fromString('GAMES'), ServerType.games);
    expect(ServerType.fromString(null), ServerType.none);
  });
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    if (sl.isRegistered<HttpClientService>()) {
      sl<HttpClientService>().dispose();
    }
    await sl.reset();
  });

  test(
    'loads servers and keeps cached data when a later request fails',
    () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        expect(request.url.path, '/v1/servers/get.php');
        expect(request.bodyFields['keySession'], 'session-key');
        if (requests == 1) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 4,
                  'name': 'First',
                  'fkOwner': 8,
                  'newMessagesCount': 3,
                  'category': 'MUSIC',
                },
                {'id': 7, 'name': 'Second'},
              ],
            }),
            200,
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
      final repository = ServerRepositoryImpl();

      final loaded = await repository.get();
      expect(loaded.isRight(), isTrue);
      expect(repository.getCached(), hasLength(2));
      expect(repository.getByIdCached(7)?.name, 'Second');
      expect(repository.getByIdCached(4)?.newMessagesCount, 3);
      expect(repository.getByIdCached(4)?.category, ServerType.music);
      expect(repository.getByIdCached(4)?.toMap()['category'], 'MUSIC');
      expect(repository.getByIdCached(99), isNull);

      repository.selectServer(4);
      expect(repository.selectedServerId, 4);
      expect(repository.selectedServer?.name, 'First');

      final failed = await repository.get();
      expect(failed.isLeft(), isTrue);
      expect(repository.getCached(), hasLength(2));
      expect(repository.selectedServer?.name, 'First');

      repository.clear();
      expect(repository.getCached(), isEmpty);
      expect(repository.getByIdCached(4), isNull);
      expect(repository.selectedServerId, isNull);
      expect(repository.selectedServer, isNull);
    },
  );

  test(
    'create and update synchronize cache and preserve omitted fields',
    () async {
      final sent = <http.Request>[];
      final client = MockClient((request) async {
        sent.add(request);
        if (request.url.path.endsWith('/get.php')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 4,
                  'name': 'Original',
                  'fkOwner': 8,
                  'fkMainChannel': 11,
                  'newMessagesCount': 6,
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/create.php')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'id': 5, 'name': 'Created', 'fkOwner': 8},
            }),
            201,
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 4,
              'name': 'Changed',
              'fkMainChannel': null,
              'category': 'GAMES',
            },
          }),
          200,
        );
      });
      sl.registerSingleton<HttpClientService>(
        HttpClientService(client: client, secureStorage: _TestStorage()),
      );
      final repository = ServerRepositoryImpl();

      await repository.get();
      final created = await repository.create(
        'Created',
        category: ServerType.games,
      );
      expect(created.isRight(), isTrue);
      expect(sent[1].bodyFields['name'], 'Created');
      expect(sent[1].bodyFields['category'], 'GAMES');
      expect(sent[1].bodyFields['keySession'], 'session-key');
      expect(repository.getByIdCached(5)?.name, 'Created');

      final updated = await repository.update(
        4,
        'Changed',
        isSetNullMainChannel: true,
        category: ServerType.games,
      );
      expect(updated.isRight(), isTrue);
      expect(sent[2].bodyFields['isSetNullMainChannel'], '1');
      expect(repository.getByIdCached(4)?.fkMainChannel, isNull);
      expect(repository.getByIdCached(4)?.fkOwner, 8);
      expect(repository.getByIdCached(4)?.newMessagesCount, 6);
      expect(repository.getByIdCached(4)?.category, ServerType.games);
      expect(repository.getCached(), hasLength(2));

      final mainChannelUpdated = await repository.update(
        4,
        'Changed',
        fkMainChannel: 12,
      );
      expect(mainChannelUpdated.isRight(), isTrue);
      expect(sent[3].bodyFields['fkMainChannel'], '12');
      expect(repository.getByIdCached(4)?.fkMainChannel, 12);
    },
  );
}

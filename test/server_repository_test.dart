import 'dart:convert';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/data/repositories/server_repository_impl.dart';
import 'package:disalive/domain/models/server.dart';
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

  test('featured server choices include only owned public servers', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'success': true,
          'data': [
            {'id': 1, 'fkOwner': 7, 'name': 'Z', 'private': 0},
            {'id': 2, 'fkOwner': 7, 'name': 'Private', 'private': 1},
            {'id': 3, 'fkOwner': 8, 'name': 'Other', 'private': 0},
            {'id': 4, 'fkOwner': 7, 'name': 'A', 'private': 0},
            {
              'id': 5,
              'fkOwner': 7,
              'name': 'Blocked',
              'private': 0,
              'isBlocked': true,
            },
          ],
        }),
        200,
      ),
    );
    sl.registerSingleton<HttpClientService>(
      HttpClientService(client: client, secureStorage: _TestStorage()),
    );
    final choices = await ServerRepositoryImpl().getFeaturedServerChoices(7);
    expect(choices.getOrElse(() => []).map((server) => server.id), [4, 1]);
  });

  test(
    'public server query sends category without replacing joined cache',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        final isPublic = request.bodyFields['public'] == '1';
        return http.Response(
          jsonEncode({
            'success': true,
            'data': isPublic
                ? [
                    {
                      'id': 9,
                      'name': 'Public',
                      'memberId': '42',
                      'memberCount': 15,
                      'onlineMemberCount': 4,
                      'permissions': [],
                    },
                  ]
                : [
                    {'id': 4, 'name': 'Joined', 'memberId': 3},
                  ],
          }),
          200,
        );
      });
      sl.registerSingleton<HttpClientService>(
        HttpClientService(client: client, secureStorage: _TestStorage()),
      );
      final repository = ServerRepositoryImpl();

      await repository.get();
      final publicResult = await repository.get(
        isPublic: true,
        category: ServerType.games,
        query: '  Команда  ',
      );

      expect(requests[0].bodyFields.containsKey('public'), isFalse);
      expect(requests[0].bodyFields.containsKey('category'), isFalse);
      expect(requests[1].bodyFields['public'], '1');
      expect(requests[1].bodyFields['category'], ServerType.games.value);
      expect(requests[1].bodyFields['query'], 'Команда');
      expect(publicResult.getOrElse(() => []).single.memberId, 42);
      expect(publicResult.getOrElse(() => []).single.permissions, isEmpty);
      expect(repository.getCached().single.id, 4);
      expect(repository.getCached().single.memberId, 3);
    },
  );

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

  test('tag search parses usage counts and sends the query', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/servers/tags.php');
      expect(request.bodyFields['keySession'], 'session-key');
      expect(request.bodyFields['query'], 'игры');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': [
            {'id': 12, 'name': 'Игры', 'usageCount': 7},
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    sl.registerSingleton<HttpClientService>(
      HttpClientService(client: client, secureStorage: _TestStorage()),
    );

    final result = await ServerRepositoryImpl().searchTags(' игры ');
    expect(result.isRight(), isTrue, reason: result.fold((failure) => failure.message, (_) => ''));
    final tag = result.getOrElse(() => []).single;
    expect(tag.id, 12);
    expect(tag.name, 'Игры');
    expect(tag.usageCount, 7);
  });

  test(
    'main role is parsed and update sends its id or an explicit reset',
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
                  'name': 'Сервер',
                  'fkMainRole': 7,
                  'mainRole': {'id': 7, 'name': 'Модератор', 'emoji': '⭐'},
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        final roleId = request.bodyFields['fkMainRole'];
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 4,
              'name': 'Сервер',
              'fkMainRole': roleId == '' ? null : int.parse(roleId!),
              'mainRole': roleId == ''
                  ? null
                  : {'id': int.parse(roleId!), 'name': 'Участник'},
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      sl.registerSingleton<HttpClientService>(
        HttpClientService(client: client, secureStorage: _TestStorage()),
      );
      final repository = ServerRepositoryImpl();
      final loaded = await repository.get();
      expect(loaded.isRight(), isTrue, reason: loaded.toString());
      expect(repository.getByIdCached(4)?.fkMainRole, 7);
      expect(repository.getByIdCached(4)?.mainRole?.name, 'Модератор');

      await repository.update(4, 'Сервер', fkMainRole: 3);
      expect(sent[1].bodyFields['fkMainRole'], '3');
      expect(repository.getByIdCached(4)?.mainRole?.name, 'Участник');

      final cleared = await repository.update(
        4,
        'Сервер',
        isSetNullMainRole: true,
      );
      expect(sent[2].bodyFields['fkMainRole'], '');
      expect(cleared.getOrElse(() => const Server()).fkMainRole, isNull);
      expect(repository.getByIdCached(4)?.mainRole, isNull);
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
                  'description': 'Original description',
                  'fkOwner': 8,
                  'fkMainChannel': 11,
                  'newMessagesCount': 6,
                  'tags': [
                    {'id': 10, 'name': 'Старый', 'usageCount': 2},
                  ],
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.path.endsWith('/create.php')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 5,
                'name': 'Created',
                'description': 'Created description',
                'fkOwner': 8,
                'tags': [
                  {'id': 11, 'name': 'Новый', 'usageCount': 1},
                ],
              },
            }),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 4,
              'name': 'Changed',
              'description': null,
              'fkMainChannel': null,
              'category': 'GAMES',
              'tags': [
                {'id': 12, 'name': 'Игры', 'usageCount': 5},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      sl.registerSingleton<HttpClientService>(
        HttpClientService(client: client, secureStorage: _TestStorage()),
      );
      final repository = ServerRepositoryImpl();

      await repository.get();
      final created = await repository.create(
        'Created',
        description: 'Created description',
        category: ServerType.games,
        tags: const ['Новый'],
      );
      expect(created.isRight(), isTrue);
      expect(sent[1].bodyFields['name'], 'Created');
      expect(sent[1].bodyFields['description'], 'Created description');
      expect(sent[1].bodyFields['category'], 'GAMES');
      expect(jsonDecode(sent[1].bodyFields['tags']!), ['Новый']);
      expect(sent[1].bodyFields['keySession'], 'session-key');
      expect(repository.getByIdCached(5)?.name, 'Created');
      expect(repository.getByIdCached(5)?.description, 'Created description');
      expect(repository.getByIdCached(5)?.tags.single.name, 'Новый');

      final updated = await repository.update(
        4,
        'Changed',
        description: '',
        isSetNullMainChannel: true,
        category: ServerType.games,
        tags: const ['Игры'],
      );
      expect(updated.isRight(), isTrue);
      expect(sent[2].bodyFields['description'], '');
      expect(jsonDecode(sent[2].bodyFields['tags']!), ['Игры']);
      expect(repository.getByIdCached(4)?.tags.single.usageCount, 5);
      expect(repository.getByIdCached(4)?.description, isNull);
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
      expect(sent[3].bodyFields.containsKey('tags'), isFalse);
      expect(repository.getByIdCached(4)?.fkMainChannel, 12);
    },
  );
}

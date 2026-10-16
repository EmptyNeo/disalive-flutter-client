import 'dart:convert';

import 'package:disalive/data/repositories/media_stats_repository_impl.dart';
import 'package:disalive/domain/models/media_stats.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _SessionStorage extends SecureStorageService {
  @override
  Future<String?> getKeySession() async => 'session-key';
}

http.Response _response(dynamic data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test(
    'parses chatId keys and fetches statistics with authentication',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return _response({
          '1': {
            'photos': 8,
            'videos': 0,
            'files': '3',
            'audio': 1,
            'links': 17,
            'mutualChatsCount': 5,
          },
          '73': {'photos': 60, 'links': 11},
          'unexpected': {'photos': 999},
        });
      });
      final httpClient = HttpClientService(
        client: client,
        secureStorage: _SessionStorage(),
      );
      addTearDown(httpClient.dispose);
      final repository = MediaStatsRepositoryImpl(httpClient: httpClient);

      final result = await repository.getAll();
      expect(result.isRight(), isTrue);
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/v1/mediaStats/get.php');
      expect(requests.single.url.queryParameters['keySession'], 'session-key');
      expect(repository.getCached().keys, unorderedEquals([1, 73]));
      expect(
        repository.getCached()[1],
        const MediaStats(
          chatId: 1,
          photos: 8,
          files: 3,
          audio: 1,
          links: 17,
          mutualChatsCount: 5,
        ),
      );
      expect(repository.getCached()[73]?.videos, 0);
      repository.clear();
      expect(repository.getCached(), isEmpty);
    },
  );

  test('accepts empty array when no statistics exist', () async {
    final httpClient = HttpClientService(
      client: MockClient((_) async => _response([])),
      secureStorage: _SessionStorage(),
    );
    addTearDown(httpClient.dispose);
    final repository = MediaStatsRepositoryImpl(httpClient: httpClient);

    expect((await repository.getAll()).isRight(), isTrue);
    expect(repository.getCached(), isEmpty);
  });
}

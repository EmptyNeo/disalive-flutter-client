import 'dart:convert';

import 'package:disalive/data/repositories/media_filter_repository_impl.dart';
import 'package:disalive/domain/models/media_filter_item.dart';
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
    'all seven filters use their PHP routes and parse typed results',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/LinkFilter.php')) {
          return _response([
            {
              'link': 'https://example.com',
              'messageId': 9,
              'time': '2026-10-17 10:00:00',
              'fkSender': 3,
              'domain': 'example.com',
              'title': 'Example',
              'description': '',
              'image': null,
            },
          ]);
        }
        if (request.url.path.endsWith('/MutualGroupsFilter.php')) {
          return _response([
            {
              'idChat': 7,
              'name': 'Group',
              'pathImage': '/resources/DefaultGroupImage.png',
              'memberCount': 4,
            },
          ]);
        }
        if (request.url.path.endsWith('/MutualServersFilter.php')) {
          return _response([
            {
              'idServer': '12',
              'name': 'Community',
              'pathAvatar': '/resources/server.png',
              'memberCount': '42',
            },
          ]);
        }
        return _response([
          {
            'idFilesMessage': 5,
            'pathFile': 'https://example.com/file',
            'originalName': 'file',
            'size': 1.5,
            'unit': 'MB',
            'objectKey': 'uploads/file',
            'messageId': 9,
            'time': '2026-10-23 10:20:30',
          },
        ]);
      });
      final httpClient = HttpClientService(
        client: client,
        secureStorage: _SessionStorage(),
      );
      addTearDown(httpClient.dispose);
      final repository = MediaFilterRepositoryImpl(httpClient: httpClient);

      final photos = await repository.getPhotos(42, limit: 10, offset: 20);
      final videos = await repository.getVideos(42);
      final files = await repository.getFiles(42);
      final audio = await repository.getAudio(42);
      final links = await repository.getLinks(42);
      final groups = await repository.getMutualGroups(42);
      final servers = await repository.getMutualServers(42);

      for (final result in [
        photos,
        videos,
        files,
        audio,
        links,
        groups,
        servers,
      ]) {
        expect(result.isRight(), isTrue);
      }
      expect(photos.getOrElse(() => []).single, isA<MediaFilterFile>());
      expect(photos.getOrElse(() => []).single.time, '2026-10-23 10:20:30');
      expect(links.getOrElse(() => []).single, isA<MediaFilterLink>());
      expect(groups.getOrElse(() => []).single, isA<MediaFilterMutualGroup>());
      expect(
        servers.getOrElse(() => []).single,
        isA<MediaFilterMutualServer>(),
      );
      expect(servers.getOrElse(() => []).single.idServer, 12);
      expect(requests.map((request) => request.url.path), [
        '/php/Filters/PhotoFilter.php',
        '/php/Filters/VideoFilter.php',
        '/php/Filters/FileFilter.php',
        '/php/Filters/AudioFilter.php',
        '/php/Filters/LinkFilter.php',
        '/php/Filters/MutualGroupsFilter.php',
        '/php/Filters/MutualServersFilter.php',
      ]);
      for (final request in requests) {
        expect(request.method, 'POST');
        expect(request.bodyFields['keySession'], 'session-key');
        expect(request.bodyFields['chatId'], '42');
      }
      expect(requests.first.bodyFields['limit'], '10');
      expect(requests.first.bodyFields['offset'], '20');
      expect(requests[1].bodyFields['limit'], '25');
      expect(requests[1].bodyFields['offset'], '0');
    },
  );

  test('an empty filter result remains an empty list', () async {
    final httpClient = HttpClientService(
      client: MockClient((_) async => _response([])),
      secureStorage: _SessionStorage(),
    );
    addTearDown(httpClient.dispose);

    final result = await MediaFilterRepositoryImpl(
      httpClient: httpClient,
    ).getPhotos(42);
    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => []), isEmpty);
  });
}

import 'dart:convert';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/data/repositories/members_repository_impl.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends SecureStorageService {
  @override
  Future<String?> getKeySession() async => 'session-key';
}

void main() {
  tearDown(() async {
    if (sl.isRegistered<HttpClientService>()) {
      sl<HttpClientService>().dispose();
    }
    await sl.reset();
  });

  test('joining a public server sends entity key and returns server', () async {
    late http.Request request;
    sl.registerSingleton<HttpClientService>(
      HttpClientService(
        client: MockClient((sent) async {
          request = sent;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'id': 12, 'name': 'Joined server', 'memberId': 78},
            }),
            201,
          );
        }),
        secureStorage: _Storage(),
      ),
    );

    final result = await MembersRepositoryImpl().create(12, EntityType.server);

    expect(request.url.path, '/v1/members/create.php');
    expect(request.bodyFields['entityId'], '12');
    expect(request.bodyFields['entityType'], 'server');
    expect(request.bodyFields['keySession'], 'session-key');
    expect(result.getOrElse(() => throw StateError('join failed')).id, 12);
  });
}

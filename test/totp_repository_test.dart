import 'dart:convert';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/data/repositories/email_repository_impl.dart';
import 'package:disalive/data/repositories/totp_repository_impl.dart';
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
    if (sl.isRegistered<HttpClientService>()) sl<HttpClientService>().dispose();
    await sl.reset();
  });

  test('TOTP status and toggle use authenticated JSON', () async {
    final requests = <http.Request>[];
    sl.registerSingleton<HttpClientService>(
      HttpClientService(
        secureStorage: _Storage(),
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/status.php')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'enabled': false,
                  'secret': 'ABC123',
                  'qrUrl': 'otpauth://totp/example',
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'enabled': true},
            }),
            200,
          );
        }),
      ),
    );
    final repository = TotpRepositoryImpl();
    final status = await repository.getStatus();
    expect(status.getOrElse(() => throw StateError('status')).secret, 'ABC123');
    final result = await repository.toggle(
      code: '012345',
      enable: true,
      secret: 'ABC123',
    );
    expect(result.getOrElse(() => false), isTrue);
    expect(requests.map((request) => request.url.path), [
      '/v1/totp/status.php',
      '/v1/totp/toggle.php',
    ]);
    final statusBody = jsonDecode(requests.first.body) as Map;
    final toggleBody = jsonDecode(requests.last.body) as Map;
    expect(requests.first.headers['content-type'], 'application/json');
    expect(statusBody['keySession'], 'session-key');
    expect(toggleBody['keySession'], 'session-key');
    expect(toggleBody['secret'], 'ABC123');
    expect(toggleBody['code'], '012345');
    expect(toggleBody['enable'], isTrue);
  });

  test('reset verification method comes from mail response', () async {
    sl.registerSingleton<HttpClientService>(
      HttpClientService(
        secureStorage: _Storage(),
        client: MockClient((request) async {
          expect(request.url.path, '/v1/mail/send.php');
          expect(request.bodyFields['email'], 'user@example.com');
          expect(request.bodyFields.containsKey('keySession'), isFalse);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'verificationMethod': 'totp'},
            }),
            200,
          );
        }),
      ),
    );
    final result = await EmailRepositoryImpl().requestPasswordResetMethod(
      'user@example.com',
    );
    expect(result.getOrElse(() => ''), 'totp');
  });
}

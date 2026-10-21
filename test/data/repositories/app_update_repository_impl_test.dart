import 'package:disalive/data/repositories/app_update_repository_impl.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('checks Android updates with the installed version header', () async {
    late http.Request sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return http.Response('''
        {"success":true,"data":{"isUpdateAvailable":true,"version":"1.0.1.0",
        "downloadUrl":"https://example.com/app.apk","sizeInBytes":0,
        "changelog":"Новое","about":"Изменения"}}
      ''', 200, headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final repository = AppUpdateRepositoryImpl(
      httpClient: HttpClientService(
        client: client,
        secureStorage: SecureStorageService(),
      ),
    );

    final result = await repository.checkAndroid('1.0.0.1');
    expect(sentRequest.method, 'GET');
    expect(sentRequest.url.path, '/v1/update/check.php');
    expect(sentRequest.url.queryParameters['platform'], 'android');
    expect(
      sentRequest.headers.entries
          .firstWhere((entry) => entry.key.toLowerCase() == 'x-current-version')
          .value,
      '1.0.0.1',
    );
    result.fold(
      (failure) => fail(failure.message),
      (update) {
        expect(update.isUpdateAvailable, isTrue);
        expect(update.version, '1.0.1.0');
        expect(update.downloadUrl, 'https://example.com/app.apk');
        expect(update.sizeInBytes, 0);
      },
    );
  });
}

import 'dart:async';

import 'package:disalive/data/repositories/auth_repository_impl.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends SecureStorageService {
  final Completer<void> release = Completer<void>();
  String? key;

  @override
  Future<void> saveKeySession(String keySession) async {
    await release.future;
    key = keySession;
  }
}

void main() {
  test(
    'invalid credentials keep server error on unauthenticated request',
    () async {
      final storage = _Storage();
      final client = HttpClientService(
        client: MockClient(
          (_) async => http.Response(
            '{"success":false,"error":"Неверный email или пароль"}',
            401,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
        secureStorage: storage,
      );
      final result = await AuthRepositoryImpl(
        httpClient: client,
        secureStorage: storage,
      ).login('123', '123', null);

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ClientFailure>());
        expect(failure.message, 'Неверный email или пароль');
      }, (_) => fail('Expected login failure'));
    },
  );

  test('successful login completes only after session key is saved', () async {
    final storage = _Storage();
    final client = HttpClientService(
      client: MockClient(
        (_) async => http.Response(
          '{"success":true,"data":{"requireTotp":false,"keySession":"secret"}}',
          200,
        ),
      ),
      secureStorage: storage,
    );
    final repository = AuthRepositoryImpl(
      httpClient: client,
      secureStorage: storage,
    );
    var completed = false;
    final login = repository.login('person@example.com', 'password', null)
      ..then((_) => completed = true);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(completed, isFalse);
    storage.release.complete();
    expect((await login).isRight(), isTrue);
    expect(storage.key, 'secret');
    expect(completed, isTrue);
  });

  test('response without session key cannot authenticate', () async {
    final storage = _Storage();
    final client = HttpClientService(
      client: MockClient(
        (_) async => http.Response(
          '{"success":true,"data":{"requireTotp":false}}',
          200,
        ),
      ),
      secureStorage: storage,
    );
    final result = await AuthRepositoryImpl(
      httpClient: client,
      secureStorage: storage,
    ).login('person@example.com', 'password', null);

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ParsingFailure>()),
      (_) => fail('Expected login failure'),
    );
  });
}

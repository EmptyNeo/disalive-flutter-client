import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:disalive/data/repositories/appeal_repository_impl.dart';
import 'package:disalive/domain/enums/appeal_target_type.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/moderation_appeal.dart';
import 'package:disalive/domain/repositories/appeal_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:disalive/presentation/features/appeals/bloc/appeal_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends SecureStorageService {
  @override
  Future<String?> getKeySession() async => 'session-key';
}

class _Repository implements AppealRepository {
  final target = const AppealTarget(
    type: AppealTargetType.server,
    id: 5,
    name: 'Сервер',
  );
  int creates = 0;
  @override
  Future<Either<Failure, List<AppealTarget>>> getTargets() async =>
      Right([target]);
  @override
  Future<Either<Failure, List<ModerationAppeal>>> getMine() async =>
      const Right([]);
  @override
  Future<Either<Failure, bool>> create(
    AppealTarget target,
    String reason,
  ) async {
    creates++;
    return const Right(true);
  }
}

class _TargetsFailRepository extends _Repository {
  @override
  Future<Either<Failure, List<AppealTarget>>> getTargets() async =>
      Left(ClientFailure('Цели временно недоступны'));

  @override
  Future<Either<Failure, List<ModerationAppeal>>> getMine() async => Right([
    const ModerationAppeal(
      id: 5,
      type: AppealTargetType.user,
      targetId: 3,
      status: 'pending',
      reason: 'Прошу пересмотреть блокировку',
    ),
  ]);
}

void main() {
  test('non-JSON appeal response identifies the failing endpoint', () async {
    final client = MockClient(
      (request) async => http.Response(
        '<html>Not found</html>',
        404,
        headers: {'content-type': 'text/html; charset=utf-8'},
      ),
    );
    final httpClient = HttpClientService(
      client: client,
      secureStorage: _Storage(),
    );
    addTearDown(httpClient.dispose);
    final result = await AppealRepositoryImpl(
      httpClient,
      _Storage(),
    ).getTargets();
    final failure = result.fold((failure) => failure, (_) => null);
    expect(failure, isA<ParsingFailure>());
    expect(
      failure!.message,
      contains('appeals/index.php?action=targets (HTTP 404)'),
    );
  });

  test(
    'account ban response preserves session instead of logging out',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': false,
            'error': 'Ваша учётная запись заблокирована',
            'data': {'code': 'ACCOUNT_BANNED'},
          }),
          403,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      final httpClient = HttpClientService(
        client: client,
        secureStorage: _Storage(),
      );
      addTearDown(httpClient.dispose);
      var loggedOut = false;
      final result = await httpClient.get<bool>(
        endpoint: 'users/get.php',
        apiType: ApiType.v1,
        fromJson: (_) => true,
        onUnauthorized: () => loggedOut = true,
      );
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<AccountBannedFailure>(),
      );
      expect(loggedOut, isFalse);
    },
  );

  test('other 403 responses do not invalidate a valid session', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'success': false, 'error': 'Доступ ограничен'}),
        403,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    final httpClient = HttpClientService(
      client: client,
      secureStorage: _Storage(),
    );
    addTearDown(httpClient.dispose);
    var loggedOut = false;
    final result = await httpClient.get<bool>(
      endpoint: 'users/get.php',
      fromJson: (_) => true,
      onUnauthorized: () => loggedOut = true,
    );
    expect(
      result.fold((failure) => failure, (_) => null),
      isA<ClientFailure>(),
    );
    expect(loggedOut, isFalse);
  });

  test('appeal history remains available when targets fail', () async {
    final bloc = AppealBloc(_TargetsFailRepository());
    addTearDown(bloc.close);
    final loaded = bloc.stream.firstWhere(
      (state) => !state.loading && state.failure != null,
    );
    bloc.add(LoadAppeals());
    final state = await loaded;
    expect(state.targetsLoaded, isFalse);
    expect(state.appeals.single.reason, 'Прошу пересмотреть блокировку');
  });

  test('appeal requests use session header and JSON body', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      final data = request.url.queryParameters['action'] == 'targets'
          ? [
              {'type': 'server', 'id': 5, 'name': 'Сервер'},
            ]
          : request.url.queryParameters['action'] == 'mine'
          ? [
              {
                'id': 3,
                'targetType': 'server',
                'targetId': 5,
                'reason': 'Причина',
                'status': 'pending',
              },
            ]
          : null;
      return http.Response(
        jsonEncode({'success': true, 'data': data}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final httpClient = HttpClientService(
      client: client,
      secureStorage: _Storage(),
    );
    addTearDown(httpClient.dispose);
    final repo = AppealRepositoryImpl(httpClient, _Storage());
    final targetResult = await repo.getTargets();
    expect(requests.length, 1);
    final targets = targetResult.fold(
      (failure) => throw StateError(failure.message),
      (items) => items,
    );
    expect(targets.single.id, 5);
    final mine = (await repo.getMine()).fold(
      (failure) => throw StateError(failure.message),
      (items) => items,
    );
    expect(mine.single.isPending, isTrue);
    expect(
      (await repo.create(
        targets.single,
        '  Нужно пересмотреть  ',
      )).fold((failure) => throw StateError(failure.message), (value) => value),
      isTrue,
    );
    expect(requests.map((r) => r.url.path).toList(), [
      '/v1/appeals/index.php',
      '/v1/appeals/index.php',
      '/v1/appeals/index.php',
    ]);
    expect(requests.map((r) => r.url.queryParameters['action']).toList(), [
      'targets',
      'mine',
      'create',
    ]);
    for (final request in requests) {
      expect(request.headers['x-session-key'], 'session-key');
      expect(request.url.queryParameters.containsKey('keySession'), isFalse);
    }
    expect(requests.last.method, 'POST');
    expect(jsonDecode(requests.last.body), {
      'targetType': 'server',
      'targetId': 5,
      'reason': 'Нужно пересмотреть',
    });
  });

  test('bloc permits only eligible target and validates reason', () async {
    final repo = _Repository();
    final bloc = AppealBloc(repo);
    addTearDown(bloc.close);
    final loaded = bloc.stream.firstWhere((state) => state.targets.isNotEmpty);
    bloc.add(LoadAppeals());
    await loaded;
    final denied = const AppealTarget(
      type: AppealTargetType.group,
      id: 8,
      name: 'Чужая группа',
    );
    bloc.add(SubmitAppeal(denied, 'Длинная причина'));
    await Future<void>.delayed(Duration.zero);
    expect(repo.creates, 0);
    final invalid = bloc.stream.firstWhere((state) => state.failure != null);
    bloc.add(SubmitAppeal(repo.target, 'коротко'));
    expect((await invalid).failure, isA<ValidationFailure>());
    final submitted = bloc.stream.firstWhere((state) => state.submitted);
    bloc.add(SubmitAppeal(repo.target, 'Обоснованная апелляция'));
    await submitted;
    expect(repo.creates, 1);
  });
}

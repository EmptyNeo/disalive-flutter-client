import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/presentation/features/server/bloc/server_deletion_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements ServerRepository {
  String method = 'email';
  String? submittedCode;
  int requests = 0;
  Failure? deletionError;

  @override
  Future<Either<Failure, String>> requestDeletionCode(int serverId) async {
    expectSync(serverId, 42);
    requests++;
    return Right(method);
  }

  @override
  Future<Either<Failure, bool>> delete(int serverId, String code) async {
    expectSync(serverId, 42);
    submittedCode = code;
    return deletionError == null ? const Right(true) : Left(deletionError!);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'uses server verification method and deletes after a six digit code',
    () async {
      final repository = _Repository()..method = 'totp';
      final bloc = ServerDeletionBloc(repository, 42);
      bloc.add(const RequestServerDeletionCode());
      await bloc.stream.firstWhere((state) => state.method == 'totp');

      bloc.add(const ConfirmServerDeletion('123'));
      await bloc.stream.firstWhere((state) => state.error != null);
      expect(repository.submittedCode, isNull);

      bloc.add(const ConfirmServerDeletion('123456'));
      await bloc.stream.firstWhere((state) => state.completed);
      expect(repository.submittedCode, '123456');
      await bloc.close();
    },
  );

  test('keeps the email method when a deletion attempt fails', () async {
    final repository = _Repository()
      ..deletionError = const ServerFailure('Код неверен');
    final bloc = ServerDeletionBloc(repository, 42);
    bloc.add(const RequestServerDeletionCode());
    await bloc.stream.firstWhere((state) => state.method == 'email');

    bloc.add(const ConfirmServerDeletion('123456'));
    final failed = await bloc.stream.firstWhere((state) => state.error != null);
    expect(failed.method, 'email');
    expect(failed.error, 'Код неверен');

    bloc.add(const RequestServerDeletionCode());
    await bloc.stream.firstWhere((state) => state.loading);
    await bloc.stream.firstWhere((state) => !state.loading);
    expect(repository.requests, 2);
    await bloc.close();
  });
}

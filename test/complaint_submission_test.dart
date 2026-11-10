import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:disalive/data/repositories/complaint_repository_impl.dart';
import 'package:disalive/domain/enums/complaint_severity.dart';
import 'package:disalive/domain/enums/complaint_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/complaint_submission.dart';
import 'package:disalive/domain/repositories/complaint_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:disalive/presentation/features/complaints/bloc/complaint_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends SecureStorageService {
  @override
  Future<String?> getKeySession() async => 'session-key';
}

class _ComplaintRepository implements ComplaintRepository {
  Either<Failure, int> result = const Right(42);

  @override
  Future<Either<Failure, int>> create(ComplaintSubmission complaint) async =>
      result;
}

Future<ComplaintState> _until(
  ComplaintBloc bloc,
  ComplaintSubmitStatus status,
) => bloc.stream.firstWhere((state) => state.status == status);

void main() {
  test('create sends the target field for each complaint type', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {'complaint_id': 73},
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final httpClient = HttpClientService(
      client: client,
      secureStorage: _Storage(),
    );
    addTearDown(httpClient.dispose);
    final repository = ComplaintRepositoryImpl(httpClient);

    for (final type in ComplaintType.values) {
      final result = await repository.create(
        ComplaintSubmission(
          type: type,
          targetId: 12,
          reason: ' Спам ',
          details: ' Подробности ',
          severity: ComplaintSeverity.high,
          targetChannelId: type == ComplaintType.message ? 5 : null,
        ),
      );
      expect(result.getOrElse(() => -1), 73);
      final request = requests.last;
      expect(request.method, 'POST');
      expect(request.url.path, '/v1/complaints/create');
      expect(request.bodyFields['keySession'], 'session-key');
      expect(request.bodyFields['complaint_type'], type.value);
      expect(request.bodyFields[type.targetField], '12');
      expect(request.bodyFields['reason'], 'Спам');
      expect(request.bodyFields['additional_details'], 'Подробности');
      expect(request.bodyFields['severity'], 'high');
      expect(request.bodyFields['target_channel'], switch (type) {
        ComplaintType.channel => '12',
        ComplaintType.message => '5',
        _ => null,
      });
      for (final other in ComplaintType.values.where(
        (other) => other != type,
      )) {
        if (type == ComplaintType.message && other == ComplaintType.channel) {
          continue;
        }
        expect(request.bodyFields.containsKey(other.targetField), isFalse);
      }
    }
  });

  test('bloc exposes failure and complaint ID on retry', () async {
    final repository = _ComplaintRepository()
      ..result = Left(ClientFailure('Отправка ограничена'));
    final bloc = ComplaintBloc(repository);
    addTearDown(bloc.close);
    const complaint = ComplaintSubmission(
      type: ComplaintType.user,
      targetId: 7,
      reason: 'Спам',
    );

    final failure = _until(bloc, ComplaintSubmitStatus.failure);
    bloc.add(const SubmitComplaint(complaint));
    expect((await failure).failure?.message, 'Отправка ограничена');

    repository.result = const Right(42);
    final success = _until(bloc, ComplaintSubmitStatus.success);
    bloc.add(const SubmitComplaint(complaint));
    expect((await success).complaintId, 42);
  });
}

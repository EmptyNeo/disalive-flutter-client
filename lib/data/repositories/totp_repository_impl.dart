import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/totp_status.dart';
import 'package:disalive/domain/repositories/totp_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class TotpRepositoryImpl implements TotpRepository {
  final HttpClientService _client = sl<HttpClientService>();

  @override
  Future<Either<Failure, TotpStatus>> getStatus() => _client.postJson(
    endpoint: 'totp/status.php',
    data: const {},
    fromJson: (json) =>
        TotpStatus.fromMap(Map<String, dynamic>.from(json as Map)),
  );

  @override
  Future<Either<Failure, bool>> toggle({
    required String code,
    required bool enable,
    String? secret,
  }) => _client.postJson(
    endpoint: 'totp/toggle.php',
    data: {'code': code, 'enable': enable, if (enable) 'secret': secret},
    fromJson: (json) => (json as Map)['enabled'] == enable,
  );
}

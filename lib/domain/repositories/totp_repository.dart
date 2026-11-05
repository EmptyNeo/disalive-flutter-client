import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/totp_status.dart';

abstract class TotpRepository {
  Future<Either<Failure, TotpStatus>> getStatus();
  Future<Either<Failure, bool>> toggle({
    required String code,
    required bool enable,
    String? secret,
  });
}

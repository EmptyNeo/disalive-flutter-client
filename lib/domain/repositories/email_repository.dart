// lib/domain/repositories/email_repository.dart

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/email_type.dart';
import 'package:disalive/domain/failures/failures.dart';

abstract class EmailRepository {
  /// Returns `totp` when the server requires an authenticator code.
  Future<Either<Failure, String>> requestPasswordResetMethod(String email);
  Future<Either<Failure, bool>> sendVerificationEmail({
    required String email,
    required EmailType type,
    String? username,
    String? password,
  });
}

// lib/data/repositories/email_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/email_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/repositories/email_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class EmailRepositoryImpl implements EmailRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();

  @override
  Future<Either<Failure, bool>> sendVerificationEmail({
    required String email,
    required EmailType type,
    String? username,
    String? password,
  }) async {
    final Map<String, dynamic> data = {'type': type.value, 'email': email};

    if (username != null) data['username'] = username;
    if (password != null) data['password'] = password;

    return await _httpClient.postFormData<bool>(
      endpoint: 'mail/send.php',
      data: data,
      apiType: ApiType.v1,
      requireAuth: false,
      fromJson: (json) {
        return json['success'] == true;
      },
    );
  }
}

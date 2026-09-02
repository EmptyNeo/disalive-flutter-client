// lib/data/repositories/ws_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/repositories/ws_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class WsRepositoryImpl extends WsRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();

  @override
  Future<Either<Failure, String>> getToken() async {
    final result = await _httpClient.postFormData<String>(
      endpoint: 'ws/connect.php',
      data: null,
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => json['token'] as String,
    );

    return result;
  }
}

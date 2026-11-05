import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/server_list_layout.dart';
import 'package:disalive/domain/repositories/server_list_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class ServerListRepositoryImpl implements ServerListRepository {
  ServerListRepositoryImpl(this._httpClient);
  final HttpClientService _httpClient;

  @override
  Future<Either<Failure, ServerListLayout>> getLayout() =>
      _httpClient.postFormData<ServerListLayout>(
        endpoint: 'serverList/get.php',
        apiType: ApiType.v1,
        requireAuth: true,
        fromJson: (json) =>
            ServerListLayout.fromMap(Map<String, dynamic>.from(json as Map)),
      );

  @override
  Future<Either<Failure, ServerListLayout>> saveLayout(
    ServerListLayout layout,
  ) => _httpClient.postFormData<ServerListLayout>(
    endpoint: 'serverList/save.php',
    apiType: ApiType.v1,
    requireAuth: true,
    data: {'layout': jsonEncode(layout.toMap())},
    fromJson: (json) =>
        ServerListLayout.fromMap(Map<String, dynamic>.from(json as Map)),
  );
}

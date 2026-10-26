import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/server_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class ServerRepositoryImpl implements ServerRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  List<Server>? _servers;
  int? _selectedServerId;

  @override
  Future<Either<Failure, List<Server>>> get({
    bool isPublic = false,
    ServerType? category,
    String? query,
  }) async {
    final search = query?.trim();
    final result = await _httpClient.postFormData<List<Server>>(
      endpoint: 'servers/get.php',
      data: isPublic
          ? {
              'public': 1,
              'category': ?category?.value,
              if (search != null && search.isNotEmpty) 'query': search,
            }
          : null,
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => (json as List)
          .map((item) => Server.fromMap(item as Map<String, dynamic>))
          .toList(),
    );

    if (!isPublic) {
      result.fold((failure) => null, (servers) => _servers = servers);
    }
    return result;
  }

  @override
  Future<Either<Failure, Server>> create(
    String name, {
    int canInvite = 1,
    int isPrivate = 0,
    ServerType? category,
    File? avatar,
    File? banner,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'canInvite': canInvite,
      'private': isPrivate,
      'category': ?category?.value,
    };

    final result = avatar == null && banner == null
        ? await _httpClient.postFormData<Server>(
            endpoint: 'servers/create.php',
            data: data,
            apiType: ApiType.v1,
            requireAuth: true,
            fromJson: (json) => Server.fromMap(json as Map<String, dynamic>),
          )
        : await _httpClient.postMultipart<Server>(
            endpoint: 'servers/create.php',
            data: data,
            files: {
              if (avatar != null) 'avatar': [avatar],
              if (banner != null) 'banner': [banner],
            },
            apiType: ApiType.v1,
            requireAuth: true,
            fromJson: (json) => Server.fromMap(json as Map<String, dynamic>),
          );

    result.fold((failure) => null, (server) {
      if (_servers != null) {
        _upsert(server);
      }
    });
    return result;
  }

  @override
  Future<Either<Failure, Server>> update(
    int id,
    String name, {
    int? canInvite,
    int? isPrivate,
    ServerType? category,
    int? fkMainChannel,
    bool isSetNullMainChannel = false,
    int? fkMainRole,
    bool isSetNullMainRole = false,
    File? avatar,
    File? banner,
    bool deleteBanner = false,
  }) async {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'canInvite': ?canInvite,
      'private': ?isPrivate,
      'category': ?category?.value,
      'fkMainChannel': ?fkMainChannel,
      if (isSetNullMainChannel) 'isSetNullMainChannel': 1,
      if (deleteBanner && banner == null) 'deleteBanner': 1,
      if (isSetNullMainRole) 'fkMainRole': '' else 'fkMainRole': ?fkMainRole,
    };

    final result = avatar == null && banner == null
        ? await _httpClient.postFormData<Map<String, dynamic>>(
            endpoint: 'servers/update.php',
            data: data,
            apiType: ApiType.v1,
            requireAuth: true,
            fromJson: (json) => json as Map<String, dynamic>,
          )
        : await _httpClient.postMultipart<Map<String, dynamic>>(
            endpoint: 'servers/update.php',
            data: data,
            files: {
              if (avatar != null) 'avatar': [avatar],
              if (banner != null) 'banner': [banner],
            },
            apiType: ApiType.v1,
            requireAuth: true,
            fromJson: (json) => json as Map<String, dynamic>,
          );

    return result.fold((failure) => Left(failure), (response) {
      final cached = getByIdCached(id);
      final server = Server.fromMap({
        if (cached != null) ...cached.toMap(),
        ...response,
        'fkMainChannel': ?fkMainChannel,
      });
      if (_servers != null) {
        _upsert(server);
      }
      return Right(server);
    });
  }

  void _upsert(Server server) {
    final servers = _servers;
    if (servers == null) return;
    final index = servers.indexWhere((item) => item.id == server.id);
    if (index == -1) {
      servers.add(server);
    } else {
      servers[index] = server;
    }
  }

  @override
  List<Server> getCached() => _servers ?? [];

  @override
  void updateCache(List<Server> servers) {
    _servers = List<Server>.from(servers);
  }

  @override
  Server? getByIdCached(int id) {
    for (final server in getCached()) {
      if (server.id == id) return server;
    }
    return null;
  }

  @override
  int? get selectedServerId => _selectedServerId;

  @override
  Server? get selectedServer =>
      _selectedServerId == null ? null : getByIdCached(_selectedServerId!);

  @override
  void selectServer(int? serverId) {
    _selectedServerId = serverId;
  }

  @override
  void clear() {
    _servers = [];
    _selectedServerId = null;
  }
}

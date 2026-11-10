import 'dart:io';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/server_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/server_tag.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class ServerRepositoryImpl implements ServerRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  List<Server>? _servers;
  int? _selectedServerId;

  @override
  Future<Either<Failure, List<Server>>> getFeaturedServerChoices(
    int ownerId,
  ) async {
    final result = await get();
    return result.map((servers) {
      final choices =
          servers
              .where(
                (server) =>
                    server.fkOwner == ownerId &&
                    server.private == 0 &&
                    server.isBlocked != true,
              )
              .toList()
            ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      return choices;
    });
  }

  @override
  Future<Either<Failure, String>> requestDeletionCode(int serverId) =>
      _httpClient.postFormData<String>(
        endpoint: 'mail/send.php',
        data: {'serverId': serverId, 'type': 'delete-server'},
        apiType: ApiType.v1,
        requireAuth: true,
        fromJson: (json) {
          final method = json is Map ? json['verificationMethod'] : null;
          if (method == 'email' || method == 'totp') return method as String;
          throw const FormatException('Сервер не указал способ подтверждения');
        },
      );

  @override
  Future<Either<Failure, bool>> delete(
    int serverId,
    String verificationCode,
  ) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'servers/delete.php',
      data: {'serverId': serverId, 'verificationCode': verificationCode},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (_) => true,
    );
    result.fold((_) => null, (_) {
      _servers?.removeWhere((server) => server.id == serverId);
      if (_selectedServerId == serverId) _selectedServerId = null;
    });
    return result;
  }

  @override
  Future<Either<Failure, List<ServerTag>>> searchTags(String query) =>
      _httpClient.postFormData<List<ServerTag>>(
        endpoint: 'servers/tags.php',
        data: {'query': query.trim()},
        apiType: ApiType.v1,
        requireAuth: true,
        fromJson: (json) => (json as List)
            .map(
              (item) =>
                  ServerTag.fromMap(Map<String, dynamic>.from(item as Map)),
            )
            .toList(),
      );

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
    String description = '',
    int canInvite = 1,
    int isPrivate = 0,
    ServerType? category,
    File? avatar,
    File? banner,
    List<String> tags = const [],
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'description': description,
      'canInvite': canInvite,
      'private': isPrivate,
      'category': ?category?.value,
      'tags': jsonEncode(tags),
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
    String? description,
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
    List<String>? tags,
  }) async {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'description': ?description,
      'canInvite': ?canInvite,
      'private': ?isPrivate,
      'category': ?category?.value,
      if (tags != null) 'tags': jsonEncode(tags),
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

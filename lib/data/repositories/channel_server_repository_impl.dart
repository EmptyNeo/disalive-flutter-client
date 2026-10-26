import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class ChannelServerRepositoryImpl implements ChannelServerRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  final Map<int, List<ChannelServer>> _cache = {};

  @override
  Future<Either<Failure, List<ChannelServer>>> get(int serverId) async {
    final result = await _httpClient.get<List<ChannelServer>>(
      endpoint: 'channelsServer/get.php',
      queryParams: {'serverId': serverId},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => (json as List)
          .map((item) => ChannelServer.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
    result.fold(
      (failure) => null,
      (channels) => updateCache(serverId, channels),
    );
    return result;
  }

  @override
  Future<Either<Failure, ChannelServer>> getById(int id) async {
    final result = await _httpClient.get<ChannelServer>(
      endpoint: 'channelsServer/get.php',
      queryParams: {'id': id},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => ChannelServer.fromMap(json as Map<String, dynamic>),
    );
    result.fold((failure) => null, _upsert);
    return result;
  }

  @override
  Future<Either<Failure, ChannelServer>> create(
    int serverId,
    String name, {
    String type = 'text',
    int? categoryId,
    bool isPrivate = false,
    int? maxParticipants,
    List<int> userIds = const [],
    List<int> roleIds = const [],
  }) async {
    final data = <String, dynamic>{
      'entityId': serverId,
      'entityType': EntityType.server.value,
      'name': name,
      'type': type,
      'categoryId': ?categoryId,
      'isPrivate': isPrivate ? 1 : 0,
      if (type == 'voice' && maxParticipants != null)
        'maxParticipants': maxParticipants,
      for (var i = 0; i < userIds.length; i++) 'userIds[$i]': userIds[i],
      for (var i = 0; i < roleIds.length; i++) 'roleIds[$i]': roleIds[i],
    };
    final result = await _httpClient.postFormData<ChannelServer>(
      endpoint: 'channelsServer/create.php',
      data: data,
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => ChannelServer.fromMap(json as Map<String, dynamic>),
    );
    result.fold((failure) => null, _upsert);
    return result;
  }

  @override
  Future<Either<Failure, ChannelServer>> update(
    int id, {
    String? name,
    int? categoryId,
    int? maxParticipants,
  }) async {
    final result = await _httpClient.postFormData<Map<String, dynamic>>(
      endpoint: 'channelsServer/update.php',
      data: {
        'id': id,
        'name': ?name,
        'categoryId': ?categoryId,
        'maxParticipants': maxParticipants?.toString() ?? '',
      },
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return result.fold((failure) => Left(failure), (response) {
      final cached = getByIdCached((response['id'] as num?)?.toInt() ?? id);
      final channel = ChannelServer.fromMap({
        if (cached != null) ...cached.toMap(),
        ...response,
        if (categoryId != null)
          'categoryId': categoryId == 0 ? null : categoryId,
      });
      _upsert(channel);
      return Right(channel);
    });
  }

  @override
  Future<Either<Failure, int>> delete(int id) async {
    final result = await _httpClient.postFormData<int>(
      endpoint: 'channelsServer/delete.php',
      data: {'id': id},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => (json['id'] as num).toInt(),
    );
    result.fold((failure) => null, (deletedId) {
      for (final channels in _cache.values) {
        channels.removeWhere((channel) => channel.id == deletedId);
      }
    });
    return result;
  }

  void _upsert(ChannelServer channel) {
    final channels = _cache[channel.serverId];
    if (channels == null) return;
    final index = channels.indexWhere((item) => item.id == channel.id);
    if (index < 0) {
      channels.add(channel);
    } else {
      channels[index] = channel;
    }
  }

  @override
  List<ChannelServer> getCached(int serverId) =>
      List<ChannelServer>.unmodifiable(_cache[serverId] ?? const []);

  @override
  ChannelServer? getByIdCached(int id) {
    for (final channels in _cache.values) {
      for (final channel in channels) {
        if (channel.id == id) return channel;
      }
    }
    return null;
  }

  @override
  void updateCache(int serverId, List<ChannelServer> channels) {
    _cache[serverId] = List<ChannelServer>.from(channels);
  }

  @override
  void clear([int? serverId]) {
    if (serverId == null) {
      _cache.clear();
    } else {
      _cache.remove(serverId);
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/media_filter_item.dart';
import 'package:disalive/domain/repositories/media_filter_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class MediaFilterRepositoryImpl implements MediaFilterRepository {
  MediaFilterRepositoryImpl({HttpClientService? httpClient})
    : _httpClient = httpClient ?? sl<HttpClientService>();

  final HttpClientService _httpClient;

  Future<Either<Failure, List<T>>> _getItems<T extends MediaFilterItem>(
    String endpoint,
    int chatId,
    T Function(Map<String, dynamic>) parse, {
    required int limit,
    required int offset,
  }) => _httpClient.postFormData<List<T>>(
    endpoint: 'Filters/$endpoint.php',
    apiType: ApiType.php,
    requireAuth: true,
    data: {'chatId': chatId, 'limit': limit, 'offset': offset},
    fromJson: (json) => (json as List)
        .map((item) => parse(Map<String, dynamic>.from(item as Map)))
        .toList(),
  );

  @override
  Future<Either<Failure, List<MediaFilterFile>>> getPhotos(
    int chatId, {
    int limit = 25,
    int offset = 0,
  }) => _getItems(
    'PhotoFilter',
    chatId,
    MediaFilterFile.fromMap,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Either<Failure, List<MediaFilterFile>>> getVideos(
    int chatId, {
    int limit = 25,
    int offset = 0,
  }) => _getItems(
    'VideoFilter',
    chatId,
    MediaFilterFile.fromMap,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Either<Failure, List<MediaFilterFile>>> getFiles(
    int chatId, {
    int limit = 25,
    int offset = 0,
  }) => _getItems(
    'FileFilter',
    chatId,
    MediaFilterFile.fromMap,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Either<Failure, List<MediaFilterFile>>> getAudio(
    int chatId, {
    int limit = 25,
    int offset = 0,
  }) => _getItems(
    'AudioFilter',
    chatId,
    MediaFilterFile.fromMap,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Either<Failure, List<MediaFilterLink>>> getLinks(
    int chatId, {
    int limit = 25,
    int offset = 0,
  }) => _getItems(
    'LinkFilter',
    chatId,
    MediaFilterLink.fromMap,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Either<Failure, List<MediaFilterMutualGroup>>> getMutualGroups(
    int chatId, {
    int limit = 25,
    int offset = 0,
  }) => _getItems(
    'MutualGroupsFilter',
    chatId,
    MediaFilterMutualGroup.fromMap,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Either<Failure, List<MediaFilterMutualServer>>> getMutualServers(
    int chatId, {
    int limit = 25,
    int offset = 0,
  }) => _getItems(
    'MutualServersFilter',
    chatId,
    MediaFilterMutualServer.fromMap,
    limit: limit,
    offset: offset,
  );
}

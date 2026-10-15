import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/category_channel.dart';
import 'package:disalive/domain/repositories/category_channel_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class CategoryChannelRepositoryImpl implements CategoryChannelRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  final Map<int, List<CategoryChannel>> _cache = {};

  @override
  Future<Either<Failure, List<CategoryChannel>>> get(int serverId) async {
    // PHP reads serverId from $_GET, while this endpoint accepts POST only.
    final result = await _httpClient.postFormData<List<CategoryChannel>>(
      endpoint: 'categories/get.php?serverId=$serverId',
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => (json as List)
          .map((item) => CategoryChannel.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
    result.fold((failure) => null, (categories) {
      updateCache(serverId, categories);
    });
    return result;
  }

  @override
  Future<Either<Failure, CategoryChannel>> create(
    int serverId,
    String name,
  ) async {
    final result = await _httpClient.postFormData<CategoryChannel>(
      endpoint: 'categories/create.php',
      data: {'serverId': serverId, 'name': name},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => CategoryChannel.fromMap(json as Map<String, dynamic>),
    );
    result.fold((failure) => null, _upsert);
    return result;
  }

  @override
  Future<Either<Failure, CategoryChannel>> update(int id, String name) async {
    final result = await _httpClient.postFormData<CategoryChannel>(
      endpoint: 'categories/update.php',
      data: {'id': id, 'name': name},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => CategoryChannel.fromMap(json as Map<String, dynamic>),
    );
    result.fold((failure) => null, _upsert);
    return result;
  }

  @override
  Future<Either<Failure, bool>> delete(int id) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'categories/delete.php',
      data: {'id': id},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) => json['success'] == true,
    );
    result.fold((failure) => null, (deleted) {
      if (deleted) {
        for (final categories in _cache.values) {
          categories.removeWhere((category) => category.id == id);
        }
      }
    });
    return result;
  }

  void _upsert(CategoryChannel category) {
    final categories = _cache[category.serverId];
    if (categories == null) return;
    final index = categories.indexWhere((item) => item.id == category.id);
    if (index < 0) {
      categories.add(category);
    } else {
      categories[index] = category;
    }
  }

  @override
  List<CategoryChannel> getCached(int serverId) =>
      List<CategoryChannel>.unmodifiable(_cache[serverId] ?? const []);

  @override
  CategoryChannel? getByIdCached(int id) {
    for (final categories in _cache.values) {
      for (final category in categories) {
        if (category.id == id) return category;
      }
    }
    return null;
  }

  @override
  void updateCache(int serverId, List<CategoryChannel> categories) {
    _cache[serverId] = List<CategoryChannel>.from(categories);
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

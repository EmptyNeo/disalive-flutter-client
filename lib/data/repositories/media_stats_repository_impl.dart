import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/media_stats.dart';
import 'package:disalive/domain/repositories/media_stats_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class MediaStatsRepositoryImpl implements MediaStatsRepository {
  MediaStatsRepositoryImpl({HttpClientService? httpClient})
    : _httpClient = httpClient ?? sl<HttpClientService>();

  final HttpClientService _httpClient;
  Map<int, MediaStats> _cache = const {};
  int _generation = 0;

  @override
  Future<Either<Failure, Map<int, MediaStats>>> getAll() async {
    final generation = ++_generation;
    final result = await _httpClient.get<Map<int, MediaStats>>(
      endpoint: 'mediaStats/get.php',
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is! Map) return <int, MediaStats>{};
        final stats = <int, MediaStats>{};
        for (final entry in json.entries) {
          final chatId = int.tryParse(entry.key.toString());
          if (chatId == null || entry.value is! Map) continue;
          stats[chatId] = MediaStats.fromMap(
            chatId,
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
        return stats;
      },
    );
    if (generation == _generation) {
      result.fold((_) {}, (stats) => _cache = Map.unmodifiable(stats));
    }
    return result;
  }

  @override
  Map<int, MediaStats> getCached() => _cache;

  @override
  void clear() {
    _generation++;
    _cache = const {};
  }
}

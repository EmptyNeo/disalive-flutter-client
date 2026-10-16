import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/media_stats.dart';
import 'package:disalive/domain/repositories/media_stats_repository.dart';
import 'package:disalive/presentation/features/media_stats/bloc/media_stats_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _StatsRepository implements MediaStatsRepository {
  Map<int, MediaStats> cache = const {};
  Either<Failure, Map<int, MediaStats>> response = const Right({});

  @override
  Future<Either<Failure, Map<int, MediaStats>>> getAll() async {
    response.fold((_) {}, (stats) => cache = stats);
    return response;
  }

  @override
  Map<int, MediaStats> getCached() => cache;

  @override
  void clear() => cache = const {};
}

void main() {
  test('loads statistics for each chat and retains cache on failure', () async {
    final repository = _StatsRepository()
      ..response = const Right({
        8: MediaStats(chatId: 8, photos: 4, mutualChatsCount: 2),
      });
    final bloc = MediaStatsBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const LoadMediaStats());
    final loaded = await bloc.stream.firstWhere((state) => state.isLoaded);
    expect(loaded.forChat(8)?.photos, 4);
    expect(loaded.forChat(9), isNull);

    repository.response = const Left(ServerFailure());
    bloc.add(const LoadMediaStats(force: true));
    final failed = await bloc.stream.firstWhere((state) => state.error != null);
    expect(failed.forChat(8)?.mutualChatsCount, 2);
  });
}

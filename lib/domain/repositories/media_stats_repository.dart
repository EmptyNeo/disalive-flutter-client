import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/media_stats.dart';

abstract class MediaStatsRepository {
  Future<Either<Failure, Map<int, MediaStats>>> getAll();

  Map<int, MediaStats> getCached();

  void clear();
}

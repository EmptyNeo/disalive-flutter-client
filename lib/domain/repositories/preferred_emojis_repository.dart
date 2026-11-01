import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/preferred_emoji.dart';

abstract class PreferredEmojisRepository {
  Future<Either<Failure, List<PreferredEmoji>>> get();

  List<PreferredEmoji> getCache();
}
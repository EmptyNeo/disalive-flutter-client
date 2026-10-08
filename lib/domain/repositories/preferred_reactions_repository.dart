import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/preferred_reaction.dart';

abstract class PreferredReactionsRepository {
  Future<Either<Failure, List<PreferredReaction>>> get();

  List<PreferredReaction> getCache();
}

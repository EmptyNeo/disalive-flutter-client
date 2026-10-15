import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/category_channel.dart';

abstract class CategoryChannelRepository {
  Future<Either<Failure, List<CategoryChannel>>> get(int serverId);
  Future<Either<Failure, CategoryChannel>> create(int serverId, String name);
  Future<Either<Failure, CategoryChannel>> update(int id, String name);
  Future<Either<Failure, bool>> delete(int id);
  List<CategoryChannel> getCached(int serverId);
  CategoryChannel? getByIdCached(int id);
  void updateCache(int serverId, List<CategoryChannel> categories);
  void clear([int? serverId]);
}

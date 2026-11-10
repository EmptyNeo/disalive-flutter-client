import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/channel_server.dart';

abstract class ChannelServerRepository {
  Future<Either<Failure, List<ChannelServer>>> get(int serverId);
  Future<Either<Failure, ChannelServer>> getById(int id);
  Future<Either<Failure, ChannelServer>> create(
    int serverId,
    String name, {
    String type = 'text',
    int? categoryId,
    bool isPrivate = false,
    bool isAdult = false,
    int? maxParticipants,
    int slowModeSeconds = 0,
    List<int> userIds = const [],
    List<int> roleIds = const [],
  });
  Future<Either<Failure, ChannelServer>> update(
    int id, {
    String? name,
    int? categoryId,
    int? maxParticipants,
    int? slowModeSeconds,
    bool? isPrivate,
    bool? isAdult,
    List<int>? userIds,
    List<int>? roleIds,
  });
  Future<Either<Failure, int>> delete(int id);
  Future<Either<Failure, ChannelServer>> updatePosition(
    int id,
    int? categoryId,
    int sortOrder,
  );
  List<ChannelServer> getCached(int serverId);
  ChannelServer? getByIdCached(int id);
  void updateCache(int serverId, List<ChannelServer> channels);
  void clear([int? serverId]);
}

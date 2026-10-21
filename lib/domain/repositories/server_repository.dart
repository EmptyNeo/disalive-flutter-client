import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/server_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/server.dart';

abstract class ServerRepository {
  Future<Either<Failure, List<Server>>> get({
    bool isPublic = false,
    ServerType? category,
    String? query,
  });

  Future<Either<Failure, Server>> create(
    String name, {
    int canInvite = 1,
    int isPrivate = 0,
    ServerType? category,
    File? avatar,
  });

  Future<Either<Failure, Server>> update(
    int id,
    String name, {
    int? canInvite,
    int? isPrivate,
    ServerType? category,
    int? fkMainChannel,
    bool isSetNullMainChannel = false,
    int? fkMainRole,
    bool isSetNullMainRole = false,
    File? avatar,
  });

  List<Server> getCached();

  void updateCache(List<Server> servers);

  Server? getByIdCached(int id);

  int? get selectedServerId;

  Server? get selectedServer;

  void selectServer(int? serverId);

  void clear();
}

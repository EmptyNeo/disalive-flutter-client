import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/server_list_layout.dart';

abstract class ServerListRepository {
  Future<Either<Failure, ServerListLayout>> getLayout();
  Future<Either<Failure, ServerListLayout>> saveLayout(ServerListLayout layout);
}

import 'dart:ui';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/user.dart';

abstract class WsRepository {
  Future<Either<Failure, String>> getToken();
}

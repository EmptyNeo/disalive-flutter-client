import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/sticker_pack.dart';

abstract class UserStickersPackRepository {
  Future<Either<Failure, StickerPack?>> create(int packId);

  Future<Either<Failure, bool>> delete(int packId);
}

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/sticker_pack.dart';

abstract class StickerPackRepository {
  Future<Either<Failure, List<StickerPack>>> get(int skip, int take);

  Future<Either<Failure, StickerPack?>> getById(int packId, int skip, int take);

  Future<Either<Failure, StickerPack>> create(String packName);

  Future<Either<Failure, bool>> update(int packId, String packName);

  List<StickerPack> getCache();
}

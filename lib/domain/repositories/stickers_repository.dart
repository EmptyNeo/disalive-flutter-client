import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/sticker_content.dart';

abstract class StickersRepository {
  Future<Either<Failure, StickerContent?>> create(int packId, File? file);

  Future<Either<Failure, bool>> delete(int stickerId, int packId);
}

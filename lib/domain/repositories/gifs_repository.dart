import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/gif_type_search.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/gif.dart';

abstract class GifsRepository {
  Future<Either<Failure, Uint8List>> crop(
    File image, {
    required int x,
    required int y,
    required int width,
    required int height,
  });
  Future<Either<Failure, List<Gif>>> get(
    GifTypeSearch type,
    String tags,
    int skip,
    int take,
  );

  List<Gif> getCache();
}

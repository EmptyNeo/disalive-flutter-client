import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/gif_type_search.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/gif.dart';

abstract class GifsRepository {
  Future<Either<Failure, List<Gif>>> get(
    GifTypeSearch type,
    String tags,
    int skip,
    int take,
  );

  List<Gif> getCache();
}

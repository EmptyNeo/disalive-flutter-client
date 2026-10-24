import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/media_filter_item.dart';

abstract class MediaFilterRepository {
  Future<Either<Failure, List<MediaFilterFile>>> getPhotos(
    int chatId, {
    int limit = 25,
    int offset = 0,
  });

  Future<Either<Failure, List<MediaFilterFile>>> getVideos(
    int chatId, {
    int limit = 25,
    int offset = 0,
  });

  Future<Either<Failure, List<MediaFilterFile>>> getFiles(
    int chatId, {
    int limit = 25,
    int offset = 0,
  });

  Future<Either<Failure, List<MediaFilterFile>>> getAudio(
    int chatId, {
    int limit = 25,
    int offset = 0,
  });

  Future<Either<Failure, List<MediaFilterLink>>> getLinks(
    int chatId, {
    int limit = 25,
    int offset = 0,
  });

  Future<Either<Failure, List<MediaFilterMutualGroup>>> getMutualGroups(
    int chatId, {
    int limit = 25,
    int offset = 0,
  });

  Future<Either<Failure, List<MediaFilterMutualServer>>> getMutualServers(
    int chatId, {
    int limit = 25,
    int offset = 0,
  });
}

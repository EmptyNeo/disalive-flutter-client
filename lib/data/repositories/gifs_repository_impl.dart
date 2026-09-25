import "package:dartz/dartz.dart";
import "package:disalive/app/di/di.dart";
import "package:disalive/domain/enums/api_type.dart";
import "package:disalive/domain/enums/gif_type_search.dart";
import "package:disalive/domain/failures/failures.dart";
import "package:disalive/domain/models/gif.dart";
import "package:disalive/domain/repositories/gifs_repository.dart";
import "package:disalive/domain/services/http_client_service.dart";

class GifsRepositoryImpl extends GifsRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  final List<Gif> _gifs = [];

  @override
  Future<Either<Failure, List<Gif>>> get(
      GifTypeSearch type,
      String tags,
      int skip,
      int take,
      ) async {
    final result = await _httpClient.postFormData<List<Gif>>(
      endpoint: "gifs/",
      data: {"action": type.value, "tags": tags, "skip": skip, "take": take},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is Map<String, dynamic> && json["result"] is List) {
          return (json["result"] as List)
              .map((e) => Gif.fromMap(e as Map<String, dynamic>))
              .toList();
        }
        return <Gif>[];
      },
    );

    result.fold(
            (failure) => null,
            (response) {
          if (skip == 0) {
            _gifs.clear();
          }
          _gifs.addAll(response);
        }
    );

    return result;
  }

  @override
  List<Gif> getCache() {
    return _gifs;
  }
}
import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/sticker_pack.dart';
import 'package:disalive/domain/repositories/sticker_pack_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class StickerPackRepositoryImpl extends StickerPackRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  final List<StickerPack> _packs = <StickerPack>[];

  @override
  Future<Either<Failure, List<StickerPack>>> get(int skip, int take) async {
    final result = await _httpClient.postFormData<List<StickerPack>>(
      endpoint: 'stickerPack/get.php',
      data: {"skip": skip, "take": take},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is List) {
          return json
              .map((e) => StickerPack.fromMap(e as Map<String, dynamic>))
              .toList();
        }
        return <StickerPack>[];
      },
    );

    result.fold((failure) => null, (response) {
      if (skip == 0) {
        _packs.clear();
      }
      _packs.addAll(response);
    });

    return result;
  }

  @override
  Future<Either<Failure, StickerPack?>> getById(
    int packId,
    int skip,
    int take,
  ) async {
    final result = await _httpClient.postFormData<StickerPack?>(
      endpoint: 'stickerPack/getById.php',
      data: {"packId": packId, "skip": skip, "take": take},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return StickerPack.fromMap(json);
        }

        return null;
      },
    );

    return result;
  }

  @override
  List<StickerPack> getCache() {
    return _packs;
  }
}

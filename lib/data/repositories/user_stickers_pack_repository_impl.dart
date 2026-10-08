import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/sticker_pack.dart';
import 'package:disalive/domain/repositories/user_stickers_pack_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class UserStickersPackRepositoryImpl extends UserStickersPackRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();

  @override
  Future<Either<Failure, StickerPack?>> create(int packId) {
    return _httpClient.postFormData<StickerPack?>(
      endpoint: "userStickerPack/create.php",
      data: {"packId": packId},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (data) {
        if (data is Map<String, dynamic>) {
          return StickerPack.fromMap(data);
        }

        return null;
      },
    );
  }

  @override
  Future<Either<Failure, bool>> delete(int packId) {
    return _httpClient.postFormData<bool>(
      endpoint: "userStickerPack/delete.php",
      data: {"packId": packId},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (data) {
        return true;
      },
    );
  }
}

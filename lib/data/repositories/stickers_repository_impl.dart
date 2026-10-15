import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/sticker_content.dart';
import 'package:disalive/domain/repositories/stickers_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class StickersRepositoryImpl extends StickersRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();

  @override
  Future<Either<Failure, StickerContent?>> create(
    int packId,
    File? file,
  ) async {
    final result = await _httpClient.postMultipart<StickerContent?>(
      endpoint: 'stickerContent/create.php',
      data: {'packId': packId},
      files: {
        'file': [file],
      },
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return StickerContent.fromMap(json);
        }
        return null;
      },
    );

    return result;
  }

  @override
  Future<Either<Failure, bool>> delete(int stickerId, int packId) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'stickerContent/delete.php',
      data: {'stickerId': stickerId, 'packId': packId},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        return true;
      },
    );

    return result;
  }
}

// lib/data/repositories/server_emoji_pack_repository_impl.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/responses/install_server_emoji_pack.dart';
import 'package:disalive/domain/models/server_emoji_pack.dart';
import 'package:disalive/domain/repositories/server_emoji_pack_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class ServerEmojiPackRepositoryImpl implements ServerEmojiPackRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();

  @override
  Future<Either<Failure, List<ServerEmojiPack>>> getPacks({
    int? serverId,
    String? categoryId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (serverId != null) queryParams['serverId'] = serverId;
    if (categoryId != null) queryParams['categoryId'] = categoryId;

    return await _httpClient.get<List<ServerEmojiPack>>(
      endpoint: 'serverEmojiPack/get.php',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map((e) => ServerEmojiPack.fromMap(e))
              .toList();
        }
        return [];
      },
    );
  }

  @override
  Future<Either<Failure, ServerEmojiPack>> createPack(int serverId) async {
    return await _httpClient.postFormData<ServerEmojiPack>(
      endpoint: 'serverEmojiPack/create.php',
      data: {'serverId': serverId},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return ServerEmojiPack.fromMap(json);
        }
        throw const FormatException('Invalid response format for createPack');
      },
    );
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> deletePack(int serverId) async {
    return await _httpClient.postFormData<Map<String, dynamic>>(
      endpoint: 'serverEmojiPack/delete.php',
      data: {'serverId': serverId},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return json;
        }
        throw const FormatException('Invalid response format for deletePack');
      },
    );
  }

  @override
  Future<Either<Failure, ServerEmojiPack>> deleteEmoji(int emojiId) async {
    return await _httpClient.postFormData<ServerEmojiPack>(
      endpoint: 'serverEmojiPack/deleteEmoji.php',
      data: {'emojiId': emojiId},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return ServerEmojiPack.fromMap(json);
        }
        throw const FormatException('Invalid response format for deleteEmoji');
      },
    );
  }

  @override
  Future<Either<Failure, InstallServerEmojiPack>> installPack({
    required int packId,
    required bool installed,
  }) async {
    return await _httpClient.postFormData<InstallServerEmojiPack>(
      endpoint: 'serverEmojiPack/install.php',
      data: {
        'packId': packId,
        'installed': installed ? 'true' : 'false',
        // PHP filter_var лучше понимает строки
      },
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return InstallServerEmojiPack.fromMap(json);
        }
        throw const FormatException('Invalid response format for installPack');
      },
    );
  }

  @override
  Future<Either<Failure, ServerEmojiPack>> uploadEmoji({
    required int serverId,
    required String name,
    required File file,
  }) async {
    return await _httpClient.postMultipart<ServerEmojiPack>(
      endpoint: 'serverEmojiPack/upload.php',
      data: {'serverId': serverId, 'name': name},
      files: {
        'file': [file],
        // Ключ 'file' должен точно совпадать с $_FILES['file'] в PHP
      },
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return ServerEmojiPack.fromMap(json);
        }
        throw const FormatException('Invalid response format for uploadEmoji');
      },
    );
  }
}

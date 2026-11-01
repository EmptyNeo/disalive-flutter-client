import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/responses/install_server_emoji_pack.dart';
import 'package:disalive/domain/models/server_emoji_pack.dart';

abstract class ServerEmojiPackRepository {
  /// GET /v1/serverEmojiPack/get.php
  Future<Either<Failure, List<ServerEmojiPack>>> getPacks({
    int? serverId,
    String? categoryId,
  });

  /// POST /v1/serverEmojiPack/create.php
  Future<Either<Failure, ServerEmojiPack>> createPack(int serverId);

  /// POST /v1/serverEmojiPack/delete.php
  Future<Either<Failure, Map<String, dynamic>>> deletePack(int serverId);

  /// POST /v1/serverEmojiPack/deleteEmoji.php
  Future<Either<Failure, ServerEmojiPack>> deleteEmoji(int emojiId);

  /// POST /v1/serverEmojiPack/install.php
  Future<Either<Failure, InstallServerEmojiPack>> installPack({
    required int packId,
    required bool installed,
  });

  /// POST /v1/serverEmojiPack/upload.php (Multipart)
  Future<Either<Failure, ServerEmojiPack>> uploadEmoji({
    required int serverId,
    required String name,
    required File file,
  });
}

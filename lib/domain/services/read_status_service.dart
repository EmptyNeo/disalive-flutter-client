import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

/// Marks messages as read using the same member update as the chat screen.
/// Server channel read positions are tracked separately by chat ID.
class ReadStatusService {
  const ReadStatusService(this._members, this._channels, this._httpClient);

  final MembersRepository _members;
  final ChannelServerRepository _channels;
  final HttpClientService _httpClient;

  Future<Either<Failure, int?>> markChat(Chat chat) async {
    if (chat.unreadCount == 0) return const Right(null);
    var lastId = chat.idLastMessage;
    if (lastId == null) {
      final latest = await _getLatestMessageId(
        chat.id,
        EntityType.chat,
        chat.id,
      );
      final failure = latest.fold<Failure?>((failure) => failure, (_) => null);
      if (failure != null) return Left(failure);
      lastId = latest.getOrElse(() => null);
    }
    if (lastId == null || lastId <= 0) return const Right(null);
    final result = await _update(chat.id, EntityType.chat, chat.id, lastId);
    return result.fold((failure) => Left(failure), (_) => Right(lastId));
  }

  Future<Either<Failure, bool>> markChannel(
    int serverId,
    ChannelServer channel,
  ) async {
    final chatId = channel.chatId;
    if (channel.newMessagesCount == 0 || chatId == null) {
      return const Right(false);
    }
    final latest = await _getLatestMessageId(
      serverId,
      EntityType.server,
      chatId,
    );
    final failure = latest.fold<Failure?>((failure) => failure, (_) => null);
    if (failure != null) return Left(failure);
    final lastId = latest.getOrElse(() => null);
    if (lastId == null || lastId <= (channel.lastIdReadMessage ?? 0)) {
      return const Right(false);
    }
    return _update(serverId, EntityType.server, chatId, lastId);
  }

  Future<Either<Failure, bool>> markServer(Server server) async {
    final serverId = server.id;
    if (serverId == null || (server.newMessagesCount ?? 0) <= 0) {
      return const Right(false);
    }

    final result = await _channels.get(serverId);
    final loadFailure = result.fold<Failure?>(
      (failure) => failure,
      (_) => null,
    );
    if (loadFailure != null) return Left(loadFailure);
    final unread = result
        .getOrElse(() => const [])
        .where(
          (channel) => channel.newMessagesCount > 0 && channel.chatId != null,
        );
    var changed = false;
    Failure? firstFailure;
    for (final channel in unread) {
      final readResult = await markChannel(serverId, channel);
      readResult.fold(
        (failure) => firstFailure ??= failure,
        (didChange) => changed |= didChange,
      );
    }
    if (firstFailure != null) return Left(firstFailure!);
    return Right(changed);
  }

  Future<Either<Failure, int?>> _getLatestMessageId(
    int entityId,
    EntityType entityType,
    int chatId,
  ) {
    // Query without touching MessageRepository's cached conversation page.
    return _httpClient.postFormData<int?>(
      endpoint: 'messages/get.php',
      apiType: ApiType.v1,
      data: {
        'chatId': chatId,
        'entityId': entityId,
        'entityType': entityType.value,
        'limit': 1,
        'lastIdMessage': 0,
      },
      fromJson: (json) {
        if (json is! Map || json['messages'] is! List) return null;
        final messages = json['messages'] as List;
        if (messages.isEmpty || messages.first is! Map) return null;
        final id = (messages.first as Map)['id'];
        return id is num ? id.toInt() : int.tryParse('$id');
      },
    );
  }

  Future<Either<Failure, bool>> _update(
    int entityId,
    EntityType entityType,
    int chatId,
    int lastId,
  ) async {
    final result = await _members.update(
      entityId: entityId,
      entityType: entityType,
      chatId: chatId,
      lastIdReadMessage: lastId,
    );
    return result.fold(
      (failure) => Left(failure),
      (updated) => updated
          ? const Right(true)
          : const Left(
              ServerFailure('Не удалось отметить сообщения прочитанными'),
            ),
    );
  }
}

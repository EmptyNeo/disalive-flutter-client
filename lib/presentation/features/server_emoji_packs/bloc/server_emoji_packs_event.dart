part of 'server_emoji_packs_bloc.dart';

abstract class ServerEmojiPacksEvent extends Equatable {
  const ServerEmojiPacksEvent();

  @override
  List<Object?> get props => [];
}

class LoadServerEmojiPacks extends ServerEmojiPacksEvent {
  final int serverId;

  const LoadServerEmojiPacks(this.serverId);

  @override
  List<Object?> get props => [serverId];
}

class CreateServerEmojiPack extends ServerEmojiPacksEvent {
  final int serverId;

  const CreateServerEmojiPack(this.serverId);

  @override
  List<Object?> get props => [serverId];
}

class UploadServerEmoji extends ServerEmojiPacksEvent {
  final int serverId;
  final String name;
  final File file;

  const UploadServerEmoji({
    required this.serverId,
    required this.name,
    required this.file,
  });

  @override
  List<Object?> get props => [serverId, name, file.path];
}

class DeleteServerEmoji extends ServerEmojiPacksEvent {
  final int serverId;
  final int emojiId;

  const DeleteServerEmoji({required this.serverId, required this.emojiId});

  @override
  List<Object?> get props => [serverId, emojiId];
}

class DeleteServerEmojiPack extends ServerEmojiPacksEvent {
  final int serverId;

  const DeleteServerEmojiPack(this.serverId);

  @override
  List<Object?> get props => [serverId];
}

class SetServerEmojiPackInstalled extends ServerEmojiPacksEvent {
  final int serverId;
  final int packId;
  final bool installed;

  const SetServerEmojiPackInstalled({
    required this.serverId,
    required this.packId,
    required this.installed,
  });

  @override
  List<Object?> get props => [serverId, packId, installed];
}

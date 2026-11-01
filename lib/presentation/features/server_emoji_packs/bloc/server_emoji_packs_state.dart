part of 'server_emoji_packs_bloc.dart';

enum ServerEmojiPacksStatus { initial, loading, loaded, failure }

class ServerEmojiPacksState extends Equatable {
  final ServerEmojiPacksStatus status;
  final int? serverId;
  final List<ServerEmojiPack> packs;
  final Failure? failure;
  final bool isWorking;

  const ServerEmojiPacksState({
    this.status = ServerEmojiPacksStatus.initial,
    this.serverId,
    this.packs = const [],
    this.failure,
    this.isWorking = false,
  });

  ServerEmojiPacksState copyWith({
    ServerEmojiPacksStatus? status,
    int? serverId,
    List<ServerEmojiPack>? packs,
    Failure? failure,
    bool? isWorking,
    bool clearFailure = false,
  }) {
    return ServerEmojiPacksState(
      status: status ?? this.status,
      serverId: serverId ?? this.serverId,
      packs: packs ?? this.packs,
      failure: clearFailure ? null : failure ?? this.failure,
      isWorking: isWorking ?? this.isWorking,
    );
  }

  @override
  List<Object?> get props => [status, serverId, packs, failure, isWorking];
}

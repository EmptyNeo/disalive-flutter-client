part of 'channel_server_bloc.dart';

abstract class ChannelServerEvent extends Equatable {
  const ChannelServerEvent();

  @override
  List<Object?> get props => [];
}

class GetServerChannels extends ChannelServerEvent {
  final int serverId;

  const GetServerChannels(this.serverId);

  @override
  List<Object?> get props => [serverId];
}

class ServerChannelUpserted extends ChannelServerEvent {
  final int serverId;
  final Map<String, dynamic> channelData;

  const ServerChannelUpserted(this.serverId, this.channelData);

  @override
  List<Object?> get props => [serverId, channelData];
}

class ServerChannelRemoved extends ChannelServerEvent {
  final int serverId;
  final int id;

  const ServerChannelRemoved(this.serverId, this.id);

  @override
  List<Object?> get props => [serverId, id];
}

class ServerChannelReadUpdated extends ChannelServerEvent {
  final int serverId;
  final int chatId;
  final int lastIdReadMessage;
  final int? newMessagesCount;

  const ServerChannelReadUpdated(
    this.serverId,
    this.chatId,
    this.lastIdReadMessage, {
    this.newMessagesCount,
  });

  @override
  List<Object?> get props => [
    serverId,
    chatId,
    lastIdReadMessage,
    newMessagesCount,
  ];
}

class ServerChannelMessageAdded extends ChannelServerEvent {
  const ServerChannelMessageAdded(
    this.serverId,
    this.chatId,
    this.messageId,
    this.isSelf,
  );

  final int serverId;
  final int chatId;
  final int messageId;
  final bool isSelf;

  @override
  List<Object?> get props => [serverId, chatId, messageId, isSelf];
}

class ServerChannelMessageRemoved extends ChannelServerEvent {
  const ServerChannelMessageRemoved(this.serverId, this.chatId, this.messageId);

  final int serverId;
  final int chatId;
  final int messageId;

  @override
  List<Object?> get props => [serverId, chatId, messageId];
}

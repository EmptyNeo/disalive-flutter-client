part of 'channel_server_bloc.dart';

abstract class ChannelServerState extends Equatable {
  const ChannelServerState();

  @override
  List<Object?> get props => [];
}

class ChannelServerInitial extends ChannelServerState {}

class ServerChannelsLoading extends ChannelServerState {
  final int serverId;
  const ServerChannelsLoading(this.serverId);

  @override
  List<Object?> get props => [serverId];
}

class ServerChannelsLoaded extends ChannelServerState {
  final int serverId;
  final List<ChannelServer> channels;
  final bool savingOrder;
  final Failure? orderFailure;

  const ServerChannelsLoaded(
    this.serverId,
    this.channels, {
    this.savingOrder = false,
    this.orderFailure,
  });

  @override
  List<Object?> get props => [serverId, channels, savingOrder, orderFailure];
}

class ServerChannelsFailure extends ChannelServerState {
  final int serverId;
  final Failure error;

  const ServerChannelsFailure(this.serverId, this.error);

  @override
  List<Object?> get props => [serverId, error];
}

part of 'servers_bloc.dart';

abstract class ServersEvent extends Equatable {
  const ServersEvent();

  @override
  List<Object?> get props => [];
}

class GetServers extends ServersEvent {
  const GetServers();
}

class SelectServer extends ServersEvent {
  const SelectServer(this.serverId);

  final int? serverId;

  @override
  List<Object?> get props => [serverId];
}

class ServerUpserted extends ServersEvent {
  final Map<String, dynamic> serverData;

  const ServerUpserted(this.serverData);

  @override
  List<Object?> get props => [serverData];
}

class ServerRemoved extends ServersEvent {
  final int id;

  const ServerRemoved(this.id);

  @override
  List<Object?> get props => [id];
}

class ServerMemberUpdated extends ServersEvent {
  final int serverId;
  final bool? muted;
  final int readReduction;
  final int? newMessagesCount;

  const ServerMemberUpdated(
    this.serverId, {
    this.muted,
    this.readReduction = 0,
    this.newMessagesCount,
  });

  @override
  List<Object?> get props => [serverId, muted, readReduction, newMessagesCount];
}

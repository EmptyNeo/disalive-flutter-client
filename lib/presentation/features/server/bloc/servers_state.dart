part of 'servers_bloc.dart';

abstract class ServersState extends Equatable {
  const ServersState();

  @override
  List<Object?> get props => [];
}

class ServersInitial extends ServersState {}

class ServersLoading extends ServersState {}

class ServersLoaded extends ServersState {
  final List<Server> servers;
  final int? selectedServerId;

  const ServersLoaded(this.servers, {this.selectedServerId});

  @override
  List<Object?> get props => [servers, selectedServerId];
}

class ServersFailure extends ServersState {
  final Failure error;

  const ServersFailure(this.error);

  @override
  List<Object?> get props => [error];
}

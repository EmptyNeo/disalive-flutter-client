part of 'featured_server_bloc.dart';

sealed class FeaturedServerEvent extends Equatable {
  const FeaturedServerEvent();

  @override
  List<Object?> get props => [];
}

class LoadFeaturedServerChoices extends FeaturedServerEvent {
  const LoadFeaturedServerChoices(this.userId);
  final int userId;

  @override
  List<Object?> get props => [userId];
}

class JoinFeaturedServer extends FeaturedServerEvent {
  const JoinFeaturedServer(this.serverId);
  final int serverId;

  @override
  List<Object?> get props => [serverId];
}

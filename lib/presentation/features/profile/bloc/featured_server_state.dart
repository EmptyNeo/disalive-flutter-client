part of 'featured_server_bloc.dart';

class FeaturedServerState extends Equatable {
  const FeaturedServerState({
    this.choices = const [],
    this.loading = false,
    this.joining = false,
    this.joinedServer,
    this.error,
  });

  final List<Server> choices;
  final bool loading;
  final bool joining;
  final Server? joinedServer;
  final String? error;

  FeaturedServerState copyWith({
    List<Server>? choices,
    bool? loading,
    bool? joining,
    Server? joinedServer,
    String? error,
    bool clearError = false,
  }) => FeaturedServerState(
    choices: choices ?? this.choices,
    loading: loading ?? this.loading,
    joining: joining ?? this.joining,
    joinedServer: joinedServer ?? this.joinedServer,
    error: clearError ? null : error ?? this.error,
  );

  @override
  List<Object?> get props => [choices, loading, joining, joinedServer, error];
}

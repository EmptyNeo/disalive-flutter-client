import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:equatable/equatable.dart';

part 'featured_server_event.dart';
part 'featured_server_state.dart';

class FeaturedServerBloc
    extends Bloc<FeaturedServerEvent, FeaturedServerState> {
  FeaturedServerBloc(this._servers, this._members)
    : super(const FeaturedServerState()) {
    on<LoadFeaturedServerChoices>(_loadChoices);
    on<JoinFeaturedServer>(_join);
  }

  final ServerRepository _servers;
  final MembersRepository _members;

  Future<void> _loadChoices(
    LoadFeaturedServerChoices event,
    Emitter<FeaturedServerState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _servers.getFeaturedServerChoices(event.userId);
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(state.copyWith(loading: false, error: failure.message)),
      (servers) => emit(state.copyWith(loading: false, choices: servers)),
    );
  }

  Future<void> _join(
    JoinFeaturedServer event,
    Emitter<FeaturedServerState> emit,
  ) async {
    if (state.joining) return;
    emit(state.copyWith(joining: true, clearError: true));
    final result = await _members.create(event.serverId, EntityType.server);
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(state.copyWith(joining: false, error: failure.message)),
      (server) => emit(state.copyWith(joining: false, joinedServer: server)),
    );
  }
}

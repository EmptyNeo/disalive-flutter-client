import 'package:bloc/bloc.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/media_stats.dart';
import 'package:disalive/domain/repositories/media_stats_repository.dart';
import 'package:equatable/equatable.dart';

part 'media_stats_event.dart';
part 'media_stats_state.dart';

class MediaStatsBloc extends Bloc<MediaStatsEvent, MediaStatsState> {
  MediaStatsBloc(this._repository) : super(const MediaStatsState()) {
    on<LoadMediaStats>(_load);
  }

  final MediaStatsRepository _repository;
  int _generation = 0;

  Future<void> _load(
    LoadMediaStats event,
    Emitter<MediaStatsState> emit,
  ) async {
    if (state.isLoading && !event.force) return;
    final generation = ++_generation;
    emit(MediaStatsState(stats: _repository.getCached(), isLoading: true));

    final result = await _repository.getAll();
    if (isClosed || generation != _generation) return;
    result.fold(
      (failure) =>
          emit(MediaStatsState(stats: _repository.getCached(), error: failure)),
      (stats) =>
          emit(MediaStatsState(stats: Map.unmodifiable(stats), isLoaded: true)),
    );
  }
}

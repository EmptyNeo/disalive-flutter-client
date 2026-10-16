part of 'media_stats_bloc.dart';

sealed class MediaStatsEvent extends Equatable {
  const MediaStatsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMediaStats extends MediaStatsEvent {
  const LoadMediaStats({this.force = false});

  final bool force;

  @override
  List<Object?> get props => [force];
}

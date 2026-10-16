part of 'media_stats_bloc.dart';

class MediaStatsState extends Equatable {
  const MediaStatsState({
    this.stats = const {},
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
  });

  final Map<int, MediaStats> stats;
  final bool isLoading;
  final bool isLoaded;
  final Failure? error;

  MediaStats? forChat(int chatId) => stats[chatId];

  @override
  List<Object?> get props => [stats, isLoading, isLoaded, error];
}

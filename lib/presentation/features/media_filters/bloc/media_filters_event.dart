part of 'media_filters_bloc.dart';

sealed class MediaFiltersEvent extends Equatable {
  const MediaFiltersEvent();

  @override
  List<Object?> get props => [];
}

final class LoadMediaFilter extends MediaFiltersEvent {
  const LoadMediaFilter({required this.chatId, required this.category});

  final int chatId;
  final MediaFilterCategory category;

  @override
  List<Object?> get props => [chatId, category];
}

final class LoadMoreMediaFilter extends MediaFiltersEvent {
  const LoadMoreMediaFilter();
}

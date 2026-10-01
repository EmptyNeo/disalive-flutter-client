// lib/presentation/features/gifs/bloc/gif_state.dart
part of 'gif_bloc.dart';

abstract class GifState extends Equatable {
  const GifState();

  @override
  List<Object?> get props => [];
}

class GifInitial extends GifState {}

class GifLoading extends GifState {}

class GifLoaded extends GifState {
  final List<Gif> gifs;
  final int skip;
  final int take;
  final bool hasReachedMax;
  final String currentTags;
  final GifTypeSearch currentType;
  final bool isLoadingMore; // 🎯 НОВЫЙ ФЛАГ

  const GifLoaded({
    required this.gifs,
    required this.skip,
    required this.take,
    required this.hasReachedMax,
    required this.currentTags,
    required this.currentType,
    this.isLoadingMore = false,
  });

  GifLoaded copyWith({
    List<Gif>? gifs,
    int? skip,
    int? take,
    bool? hasReachedMax,
    String? currentTags,
    GifTypeSearch? currentType,
    bool? isLoadingMore,
  }) {
    return GifLoaded(
      gifs: gifs ?? this.gifs,
      skip: skip ?? this.skip,
      take: take ?? this.take,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentTags: currentTags ?? this.currentTags,
      currentType: currentType ?? this.currentType,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [gifs, skip, take, hasReachedMax, currentTags, currentType, isLoadingMore];
}

class GifError extends GifState {
  final Failure failure;

  const GifError(this.failure);

  @override
  List<Object?> get props => [failure];
}
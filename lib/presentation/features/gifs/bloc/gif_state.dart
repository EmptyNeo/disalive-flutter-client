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
  final int skip; // Следующее значение skip для пагинации
  final int take;
  final bool hasReachedMax; // true, если пришло меньше гифок, чем requested take
  final String currentTags;
  final GifTypeSearch currentType;

  const GifLoaded({
    required this.gifs,
    required this.skip,
    required this.take,
    required this.hasReachedMax,
    required this.currentTags,
    required this.currentType,
  });

  GifLoaded copyWith({
    List<Gif>? gifs,
    int? skip,
    int? take,
    bool? hasReachedMax,
    String? currentTags,
    GifTypeSearch? currentType,
  }) {
    return GifLoaded(
      gifs: gifs ?? this.gifs,
      skip: skip ?? this.skip,
      take: take ?? this.take,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentTags: currentTags ?? this.currentTags,
      currentType: currentType ?? this.currentType,
    );
  }

  @override
  List<Object?> get props => [gifs, skip, take, hasReachedMax, currentTags, currentType];
}

class GifError extends GifState {
  final Failure failure;

  const GifError(this.failure);

  @override
  List<Object?> get props => [failure];
}
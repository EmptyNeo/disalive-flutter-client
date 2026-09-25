part of 'gif_bloc.dart';

abstract class GifEvent extends Equatable {
  const GifEvent();

  @override
  List<Object?> get props => [];
}

/// Событие для загрузки гифок (первичная загрузка или пагинация)
class LoadGifs extends GifEvent {
  final GifTypeSearch type;
  final String tags;
  final int skip;
  final int take;

  const LoadGifs({
    required this.type,
    required this.tags,
    required this.skip,
    required this.take,
  });

  @override
  List<Object?> get props => [type, tags, skip, take];
}

/// Событие для очистки списка (например, при смене вкладки или очистке поиска)
class ClearGifs extends GifEvent {
  const ClearGifs();
}
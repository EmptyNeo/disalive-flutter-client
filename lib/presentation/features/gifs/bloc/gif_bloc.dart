import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:disalive/domain/enums/gif_type_search.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/gif.dart';
import 'package:disalive/domain/repositories/gifs_repository.dart';

part 'gif_event.dart';
part 'gif_state.dart';

class GifBloc extends Bloc<GifEvent, GifState> {
  final GifsRepository _gifsRepository;

  GifBloc(this._gifsRepository) : super(GifInitial()) {
    on<LoadGifs>(_onLoadGifs);
    on<ClearGifs>(_onClearGifs);
  }

  Future<void> _onLoadGifs(LoadGifs event, Emitter<GifState> emit) async {
    // 🎯 ШАГ 1: ПРОВЕРКА КЭША (Мгновенная отрисовка)
    if (event.skip == 0) {
      final cachedGifs = _gifsRepository.getCache();
      if (cachedGifs.isNotEmpty) {
        emit(GifLoaded(
          gifs: cachedGifs,
          skip: event.take,
          take: event.take,
          hasReachedMax: false,
          currentTags: event.tags,
          currentType: event.type,
        ));
      } else {
        emit(GifLoading());
      }
    } else {
      // 🎯 ДЛЯ ПАГИНАЦИИ: Помечаем, что идет загрузка
      final currentState = state;
      if (currentState is GifLoaded) {
        emit(currentState.copyWith(isLoadingMore: true));
      }
    }

    // 🎯 ШАГ 2: СЕТЕВОЙ ЗАПРОС
    final result = await _gifsRepository.get(
      event.type,
      event.tags,
      event.skip,
      event.take,
    );

    result.fold(
          (failure) {
        if (event.skip == 0 && state is! GifLoaded) {
          emit(GifError(failure));
        } else if (event.skip > 0 && state is GifLoaded) {
          // 🎯 При ошибке пагинации снимаем флаг загрузки
          emit((state as GifLoaded).copyWith(isLoadingMore: false));
        }
      },
          (fetchedGifs) {
        final currentState = state;
        List<Gif> updatedGifs;

        if (event.skip == 0) {
          updatedGifs = fetchedGifs;
        } else if (currentState is GifLoaded) {
          updatedGifs = [...currentState.gifs, ...fetchedGifs];
        } else {
          updatedGifs = fetchedGifs;
        }

        final hasReachedMax = fetchedGifs.length < event.take;

        emit(
          GifLoaded(
            gifs: updatedGifs,
            skip: event.skip + event.take,
            take: event.take,
            hasReachedMax: hasReachedMax,
            currentTags: event.tags,
            currentType: event.type,
            isLoadingMore: false, // 🎯 Снимаем флаг после загрузки
          ),
        );
      },
    );
  }

  void _onClearGifs(ClearGifs event, Emitter<GifState> emit) {
    emit(GifInitial());
  }
}
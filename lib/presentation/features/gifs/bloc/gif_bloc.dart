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
        // Показываем кэш мгновенно, не дожидаясь сети
        emit(GifLoaded(
          gifs: cachedGifs,
          skip: event.take,
          take: event.take,
          hasReachedMax: false, // Пока не знаем, есть ли ещё, пусть грузит
          currentTags: event.tags,
          currentType: event.type,
        ));
        // ВАЖНО: Мы НЕ делаем return здесь. Код пойдет дальше и обновит данные в фоне.
      } else {
        // Если кэша нет, показываем спиннер
        emit(GifLoading());
      }
    }

    // 🎯 ШАГ 2: СЕТЕВОЙ ЗАПРОС (Обновление данных)
    final result = await _gifsRepository.get(
      event.type,
      event.tags,
      event.skip,
      event.take,
    );

    result.fold(
          (failure) {
        // Показываем ошибку только если это первая загрузка и кэша не было
        if (event.skip == 0 && state is! GifLoaded) {
          emit(GifError(failure));
        }
        // Если это пагинация (skip > 0) и произошла ошибка, мы просто ничего не эмитим.
        // Список останется на экране, пользователь сможет попробовать проскроллить еще раз.
      },
          (fetchedGifs) {
        final currentState = state;
        List<Gif> updatedGifs;

        // 🎯 КЛЮЧЕВАЯ ЛОГИКА ПАГИНАЦИИ:
        if (event.skip == 0) {
          // Новая загрузка или новый поиск: заменяем список полностью
          updatedGifs = fetchedGifs;
        } else if (currentState is GifLoaded) {
          // Пагинация: добавляем новые гифки в конец существующего списка
          updatedGifs = [...currentState.gifs, ...fetchedGifs];
        } else {
          updatedGifs = fetchedGifs;
        }

        // Если пришло меньше гифок, чем мы запросили (take), значит, мы достигли конца
        final hasReachedMax = fetchedGifs.length < event.take;

        emit(
          GifLoaded(
            gifs: updatedGifs,
            skip: event.skip + event.take, // Готовим skip для следующего запроса
            take: event.take,
            hasReachedMax: hasReachedMax,
            currentTags: event.tags,
            currentType: event.type,
          ),
        );
      },
    );
  }

  void _onClearGifs(ClearGifs event, Emitter<GifState> emit) {
    emit(GifInitial());
  }
}
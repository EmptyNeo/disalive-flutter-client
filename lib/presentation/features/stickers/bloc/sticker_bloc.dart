import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/sticker_pack.dart';
import 'package:disalive/domain/repositories/sticker_pack_repository.dart';

part 'sticker_event.dart';
part 'sticker_state.dart';

class StickerBloc extends Bloc<StickerEvent, StickerState> {
  final StickerPackRepository _repository;

  StickerBloc(this._repository) : super(StickerInitial()) {
    on<LoadStickerPacks>(_onLoadStickerPacks);
    on<LoadStickerPackDetails>(_onLoadStickerPackDetails);
    on<ClearStickers>(_onClearStickers);
  }

  Future<void> _onLoadStickerPacks(
      LoadStickerPacks event,
      Emitter<StickerState> emit,
      ) async {
    // 🎯 ШАГ 1: ПРОВЕРКА КЭША (Мгновенная отрисовка)
    if (event.skip == 0) {
      final cachedPacks = _repository.getCache();
      if (cachedPacks.isNotEmpty) {
        // Если кэш есть, сразу показываем его пользователю!
        emit(StickerLoaded(
          packs: cachedPacks,
          skip: event.take, // Готовим следующий skip
          take: event.take,
          hasReachedMax: false, // Пока не знаем, есть ли ещё, пусть грузит
        ));
        // ВАЖНО: Мы НЕ делаем return здесь. Мы продолжаем выполнение,
        // чтобы в фоне обновить данные с сервера.
      } else {
        // Если кэша нет, показываем спиннер
        emit(StickerLoading());
      }
    }

    // 🎯 ШАГ 2: СЕТЕВОЙ ЗАПРОС (Обновление данных)
    final result = await _repository.get(event.skip, event.take);

    result.fold(
          (failure) {
        // Если это первая загрузка и кэша не было, показываем ошибку.
        // Если кэш был, мы просто игнорируем ошибку, чтобы не ломать UX старыми данными.
        if (event.skip == 0 && state is! StickerLoaded) {
          emit(StickerError(failure));
        }
      },
          (fetchedPacks) {
        final currentState = state;
        List<StickerPack> updatedPacks;

        if (event.skip == 0) {
          // Перезаписываем кэш свежими данными с сервера
          updatedPacks = fetchedPacks;
        } else if (currentState is StickerLoaded) {
          // При пагинации добавляем новые паки к существующим
          updatedPacks = [...currentState.packs, ...fetchedPacks];
        } else {
          updatedPacks = fetchedPacks;
        }

        emit(StickerLoaded(
          packs: updatedPacks,
          skip: event.skip + event.take,
          take: event.take,
          hasReachedMax: fetchedPacks.length < event.take,
          activePack: currentState is StickerLoaded ? currentState.activePack : null,
        ));
      },
    );
  }

  Future<void> _onLoadStickerPackDetails(
      LoadStickerPackDetails event,
      Emitter<StickerState> emit,
      ) async {
    final currentState = state;
    if (currentState is! StickerLoaded) return;

    emit(currentState.copyWith(isLoadingActivePack: true));

    final result = await _repository.getById(
      event.packId,
      event.skip,
      event.take,
    );

    result.fold(
          (failure) {
        emit(currentState.copyWith(isLoadingActivePack: false));
      },
          (fetchedPack) {
        if (fetchedPack != null) {
          StickerPack updatedPack;

          // Если это пагинация внутри уже открытого пака, объединяем стикеры
          if (currentState.activePack?.id == event.packId && event.skip > 0) {
            updatedPack = StickerPack(
              id: fetchedPack.id,
              name: fetchedPack.name,
              isCreator: fetchedPack.isCreator,
              hasPack: fetchedPack.hasPack,
              attachments: [
                ...(currentState.activePack?.attachments ?? []),
                ...?fetchedPack.attachments,
              ],
            );
          } else {
            updatedPack = fetchedPack;
          }

          emit(currentState.copyWith(
            activePack: updatedPack,
            isLoadingActivePack: false,
          ));
        } else {
          emit(currentState.copyWith(isLoadingActivePack: false));
        }
      },
    );
  }

  void _onClearStickers(ClearStickers event, Emitter<StickerState> emit) {
    emit(StickerInitial());
  }
}
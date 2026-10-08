import 'package:bloc/bloc.dart';
import 'package:disalive/domain/repositories/user_stickers_pack_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/sticker_pack.dart';
import 'package:disalive/domain/repositories/sticker_pack_repository.dart';

part 'stickers_pack_event.dart';

part 'stickers_pack_state.dart';

class StickersPackBloc extends Bloc<StickerPackEvent, StickersPackState> {
  final StickerPackRepository _repository;
  final UserStickersPackRepository _userStickersPackRepository;

  StickersPackBloc(this._repository, this._userStickersPackRepository)
    : super(StickersPackInitial()) {
    on<LoadStickerPacks>(_onLoadStickerPacks);
    on<LoadStickerPackDetails>(_onLoadStickerPackDetails);
    on<ClearStickers>(_onClearStickers);
    on<CreateStickerPack>(_onCreateStickerPack);
    on<UpdateStickerPack>(_onUpdateStickerPack);
    on<AddStickerPack>(_onAddStickerPack);
    on<RemoveStickerPack>(_onRemoveStickerPack);
  }

  Future<void> _onLoadStickerPacks(
    LoadStickerPacks event,
    Emitter<StickersPackState> emit,
  ) async {
    // 🎯 ШАГ 1: ПРОВЕРКА КЭША (Мгновенная отрисовка)
    if (event.skip == 0) {
      final cachedPacks = _repository.getCache();
      if (cachedPacks.isNotEmpty) {
        // Если кэш есть, сразу показываем его пользователю!
        emit(
          StickersPackLoaded(
            packs: cachedPacks,
            skip: event.take, // Готовим следующий skip
            take: event.take,
            hasReachedMax: false, // Пока не знаем, есть ли ещё, пусть грузит
          ),
        );
        // ВАЖНО: Мы НЕ делаем return здесь. Мы продолжаем выполнение,
        // чтобы в фоне обновить данные с сервера.
      } else {
        // Если кэша нет, показываем спиннер
        emit(StickersPackLoading());
      }
    }

    // 🎯 ШАГ 2: СЕТЕВОЙ ЗАПРОС (Обновление данных)
    final result = await _repository.get(event.skip, event.take);

    result.fold(
      (failure) {
        // Если это первая загрузка и кэша не было, показываем ошибку.
        // Если кэш был, мы просто игнорируем ошибку, чтобы не ломать UX старыми данными.
        if (event.skip == 0 && state is! StickersPackLoaded) {
          emit(StickersPackError(failure));
        }
      },
      (fetchedPacks) {
        final currentState = state;
        List<StickerPack> updatedPacks;

        if (event.skip == 0) {
          // Перезаписываем кэш свежими данными с сервера
          updatedPacks = fetchedPacks;
        } else if (currentState is StickersPackLoaded) {
          // При пагинации добавляем новые паки к существующим
          updatedPacks = [...currentState.packs, ...fetchedPacks];
        } else {
          updatedPacks = fetchedPacks;
        }

        emit(
          StickersPackLoaded(
            packs: updatedPacks,
            skip: event.skip + event.take,
            take: event.take,
            hasReachedMax: fetchedPacks.length < event.take,
            activePack: currentState is StickersPackLoaded
                ? currentState.activePack
                : null,
          ),
        );
      },
    );
  }

  Future<void> _onLoadStickerPackDetails(
    LoadStickerPackDetails event,
    Emitter<StickersPackState> emit,
  ) async {
    final currentState = state;
    if (currentState is! StickersPackLoaded) return;

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

          emit(
            currentState.copyWith(
              activePack: updatedPack,
              isLoadingActivePack: false,
            ),
          );
        } else {
          emit(currentState.copyWith(isLoadingActivePack: false));
        }
      },
    );
  }

  Future<void> _onCreateStickerPack(
    CreateStickerPack event,
    Emitter<StickersPackState> emit,
  ) async {
    final result = await _repository.create(event.packName);
    result.fold((failure) => emit(StickersPackError(failure)), (newPack) {
      if (state is StickersPackLoaded) {
        final current = state as StickersPackLoaded;
        // Добавляем новый пак в начало списка
        emit(current.copyWith(packs: [newPack, ...current.packs]));
      }
    });
  }

  // 🎯 ОБРАБОТЧИК ОБНОВЛЕНИЯ
  Future<void> _onUpdateStickerPack(
    UpdateStickerPack event,
    Emitter<StickersPackState> emit,
  ) async {
    final result = await _repository.update(event.packId, event.packName);
    result.fold((failure) => emit(StickersPackError(failure)), (success) {
      if (success && state is StickersPackLoaded) {
        final current = state as StickersPackLoaded;
        final updatedPacks = current.packs.map((p) {
          if (p.id == event.packId) {
            return StickerPack(
              id: p.id,
              name: event.packName,
              isCreator: p.isCreator,
              attachments: p.attachments,
              hasPack: p.hasPack,
            );
          }
          return p;
        }).toList();
        emit(current.copyWith(packs: updatedPacks));
      }
    });
  }

  Future<void> _onAddStickerPack(
    AddStickerPack event,
    Emitter<StickersPackState> emit,
  ) async {
    final result = await _userStickersPackRepository.create(event.packId);

    result.fold((failure) => emit(StickersPackError(failure)), (updatedPack) {
      if (state is StickersPackLoaded) {
        final current = state as StickersPackLoaded;

        final updatedPacks = current.packs.map((p) {
          if (p.id == event.packId) {
            // 🎯 Если сервер вернул обновлённый пак (с hasPack: true), используем его
            // Иначе просто меняем статус локально
            if (updatedPack != null) {
              return updatedPack;
            }
            return StickerPack(
              id: p.id,
              name: p.name,
              isCreator: p.isCreator,
              attachments: p.attachments,
              hasPack: true,
            );
          }
          return p;
        }).toList();

        emit(current.copyWith(packs: updatedPacks));
      }
    });
  }

  Future<void> _onRemoveStickerPack(
    RemoveStickerPack event,
    Emitter<StickersPackState> emit,
  ) async {
    final result = await _userStickersPackRepository.delete(event.packId);

    result.fold((failure) => emit(StickersPackError(failure)), (success) {
      if (success && state is StickersPackLoaded) {
        final current = state as StickersPackLoaded;

        final updatedPacks = current.packs.map((p) {
          if (p.id == event.packId) {
            return StickerPack(
              id: p.id,
              name: p.name,
              isCreator: p.isCreator,
              attachments: p.attachments,
              hasPack: false,
            );
          }
          return p;
        }).toList();

        emit(current.copyWith(packs: updatedPacks));
      }
    });
  }

  void _onClearStickers(ClearStickers event, Emitter<StickersPackState> emit) {
    emit(StickersPackInitial());
  }
}

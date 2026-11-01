import 'package:bloc/bloc.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/preferred_emoji.dart';
import 'package:disalive/domain/repositories/preferred_emojis_repository.dart';
import 'package:equatable/equatable.dart';

part 'preferred_emojis_event.dart';

part 'preferred_emojis_state.dart';

class PreferredEmojisBloc
    extends Bloc<PreferredEmojisEvent, PreferredEmojisState> {
  final PreferredEmojisRepository _preferredEmojisRepository;

  PreferredEmojisBloc(this._preferredEmojisRepository)
    : super(PreferredEmojisInitial()) {
    on<LoadPreferredEmojis>(_onLoad);
    on<UpsertPreferredEmoji>(_onUpsert);
  }

  Future<void> _onLoad(
    LoadPreferredEmojis event,
    Emitter<PreferredEmojisState> emit,
  ) async {
    final result = await _preferredEmojisRepository.get();

    result.fold(
      (failure) => emit(PreferredEmojisFailure(failure)),
      (emojis) => emit(PreferredEmojisLoaded(emojis)),
    );
  }

  void _onUpsert(
    UpsertPreferredEmoji event,
    Emitter<PreferredEmojisState> emit,
  ) {
    if (state is! PreferredEmojisLoaded) return;

    final currentState = state as PreferredEmojisLoaded;
    final emojis = List<PreferredEmoji>.from(currentState.emojis);

    // Ищем существующий эмодзи
    final index = emojis.indexWhere((e) => e.emoji == event.emoji);

    if (index != -1) {
      // Обновляем существующий: инкрементируем счетчик и обновляем дату
      final existing = emojis[index];
      emojis[index] = existing.copyWith(
        useCount: (existing.useCount ?? 0) + 1,
        lastUseDatetime: DateTime.now().toIso8601String(),
      );

      // Перемещаем на первое место (самые частые сверху)
      final updated = emojis.removeAt(index);
      emojis.insert(0, updated);
    } else {
      // Добавляем новый эмодзи
      emojis.insert(
        0,
        PreferredEmoji(
          emoji: event.emoji,
          useCount: 1,
          lastUseDatetime: DateTime.now().toIso8601String(),
        ),
      );

      // Ограничиваем до 10 эмодзи
      if (emojis.length > 10) {
        emojis.removeLast();
      }
    }

    emit(PreferredEmojisLoaded(emojis));
  }
}

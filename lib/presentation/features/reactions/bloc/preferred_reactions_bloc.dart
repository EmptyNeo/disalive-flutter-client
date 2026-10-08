import 'package:bloc/bloc.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/preferred_reaction.dart';
import 'package:disalive/domain/repositories/preferred_reactions_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:equatable/equatable.dart';

part 'preferred_reactions_event.dart';

part 'preferred_reactions_state.dart';

class PreferredReactionsBloc
    extends Bloc<PreferredReactionsEvent, PreferredReactionsState> {
  final PreferredReactionsRepository _preferredReactionsRepository;

  PreferredReactionsBloc(this._preferredReactionsRepository)
    : super(PreferredReactionsInitial()) {
    on<LoadPreferredReactions>(_onLoad);
    on<UpsertPreferredReaction>(_onUpsert);
  }

  Future<void> _onLoad(
    LoadPreferredReactions event,
    Emitter<PreferredReactionsState> emit,
  ) async {
    final result = await _preferredReactionsRepository.get();

    result.fold(
      (failure) => emit(PreferredReactionsFailure(failure)),
      (reactions) => emit(PreferredReactionsLoaded(reactions)),
    );
  }

  void _onUpsert(
    UpsertPreferredReaction event,
    Emitter<PreferredReactionsState> emit,
  ) {
    if (state is! PreferredReactionsLoaded) return;

    final currentState = state as PreferredReactionsLoaded;
    final reactions = List<PreferredReaction>.from(currentState.reactions);

    // Ищем существующую реакцию
    final index = reactions.indexWhere(
      (r) => r.nameReaction == event.nameReaction,
    );

    if (index != -1) {
      // Обновляем существующую: инкрементируем счетчик и обновляем дату
      final existing = reactions[index];
      reactions[index] = existing.copyWith(
        useCount: (existing.useCount ?? 0) + 1,
        lastUseDatetime: DateTime.now().toIso8601String(),
      );

      // Перемещаем на первое место (самые частые сверху)
      final updated = reactions.removeAt(index);
      reactions.insert(0, updated);
    } else {
      // Добавляем новую реакцию
      reactions.insert(
        0,
        PreferredReaction(
          nameReaction: event.nameReaction,
          useCount: 1,
          lastUseDatetime: DateTime.now().toIso8601String(),
        ),
      );

      // Ограничиваем до 10 реакций
      if (reactions.length > 10) {
        reactions.removeLast();
      }
    }

    emit(PreferredReactionsLoaded(reactions));
  }
}

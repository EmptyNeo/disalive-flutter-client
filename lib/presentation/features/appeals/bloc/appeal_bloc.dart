import 'package:bloc/bloc.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/moderation_appeal.dart';
import 'package:disalive/domain/repositories/appeal_repository.dart';

sealed class AppealEvent {}

class LoadAppeals extends AppealEvent {}

class SubmitAppeal extends AppealEvent {
  SubmitAppeal(this.target, this.reason);
  final AppealTarget target;
  final String reason;
}

class AppealState {
  const AppealState({
    this.loading = false,
    this.submitting = false,
    this.submitted = false,
    this.targets = const [],
    this.appeals = const [],
    this.targetsLoaded = false,
    this.failure,
  });

  final bool loading;
  final bool submitting;
  final bool submitted;
  final List<AppealTarget> targets;
  final List<ModerationAppeal> appeals;
  final bool targetsLoaded;
  final Failure? failure;

  bool canAppeal(AppealTarget target) =>
      targets.any((item) => item.type == target.type && item.id == target.id);

  bool isPending(AppealTarget target) => appeals.any(
    (item) =>
        item.type == target.type &&
        item.targetId == target.id &&
        item.isPending,
  );
}

class AppealBloc extends Bloc<AppealEvent, AppealState> {
  AppealBloc(this._repository) : super(const AppealState()) {
    on<LoadAppeals>(_load);
    on<SubmitAppeal>(_submit);
  }

  final AppealRepository _repository;

  Future<void> _load(LoadAppeals event, Emitter<AppealState> emit) async {
    emit(const AppealState(loading: true));
    final targets = await _repository.getTargets();
    final mine = await _repository.getMine();
    final targetItems = targets.fold((_) => <AppealTarget>[], (items) => items);
    final appealItems = mine.fold(
      (_) => <ModerationAppeal>[],
      (items) => items,
    );
    final failure = targets.fold<Failure?>(
      (error) => error,
      (_) => mine.fold<Failure?>((error) => error, (_) => null),
    );
    emit(
      AppealState(
        targets: targetItems,
        appeals: appealItems,
        targetsLoaded: targets.isRight(),
        failure: failure,
      ),
    );
  }

  Future<void> _submit(SubmitAppeal event, Emitter<AppealState> emit) async {
    if (state.submitting ||
        !state.canAppeal(event.target) ||
        state.isPending(event.target)) {
      return;
    }
    final reason = event.reason.trim();
    if (reason.length < 10 || reason.length > 4000) {
      emit(
        AppealState(
          targets: state.targets,
          appeals: state.appeals,
          targetsLoaded: state.targetsLoaded,
          failure: const ValidationFailure({
            'reason': 'Введите от 10 до 4000 символов',
          }),
        ),
      );
      return;
    }
    emit(
      AppealState(
        targets: state.targets,
        appeals: state.appeals,
        targetsLoaded: state.targetsLoaded,
        submitting: true,
      ),
    );
    final result = await _repository.create(event.target, reason);
    result.fold(
      (failure) => emit(
        AppealState(
          targets: state.targets,
          appeals: state.appeals,
          targetsLoaded: state.targetsLoaded,
          failure: failure,
        ),
      ),
      (_) => emit(
        AppealState(
          targets: state.targets,
          appeals: state.appeals,
          targetsLoaded: state.targetsLoaded,
          submitted: true,
        ),
      ),
    );
  }
}

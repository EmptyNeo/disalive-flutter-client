import 'package:bloc/bloc.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:equatable/equatable.dart';

part 'server_deletion_event.dart';
part 'server_deletion_state.dart';

class ServerDeletionBloc
    extends Bloc<ServerDeletionEvent, ServerDeletionState> {
  ServerDeletionBloc(this._repository, this.serverId)
    : super(const ServerDeletionState()) {
    on<RequestServerDeletionCode>(_requestCode);
    on<ConfirmServerDeletion>(_confirm);
  }

  final ServerRepository _repository;
  final int serverId;

  Future<void> _requestCode(
    RequestServerDeletionCode event,
    Emitter<ServerDeletionState> emit,
  ) async {
    if (state.loading || state.submitting || state.completed) return;
    emit(ServerDeletionState(loading: true, method: state.method));
    final result = await _repository.requestDeletionCode(serverId);
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(
        ServerDeletionState(method: state.method, error: failure.message),
      ),
      (method) => emit(ServerDeletionState(method: method)),
    );
  }

  Future<void> _confirm(
    ConfirmServerDeletion event,
    Emitter<ServerDeletionState> emit,
  ) async {
    if (state.method == null ||
        state.loading ||
        state.submitting ||
        state.completed) {
      return;
    }
    final code = event.code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      emit(
        ServerDeletionState(
          method: state.method,
          error: 'Введите шестизначный код',
        ),
      );
      return;
    }
    emit(ServerDeletionState(method: state.method, submitting: true));
    final result = await _repository.delete(serverId, code);
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(
        ServerDeletionState(method: state.method, error: failure.message),
      ),
      (_) => emit(ServerDeletionState(method: state.method, completed: true)),
    );
  }
}

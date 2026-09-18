import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_session_type.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:equatable/equatable.dart';
import 'package:disalive/domain/models/session.dart';
import 'package:disalive/domain/repositories/session_repository.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';

part 'session_event.dart';

part 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final UserRepository _userRepository;
  final SessionRepository _sessionRepository;
  final SecureStorageService _secureStorage;
  final WsEventBus _eventBus;

  StreamSubscription? _deleteSubscription;

  final String tableName = 'SessionUser';

  SessionBloc(
    this._userRepository,
    this._sessionRepository,
    this._secureStorage,
    this._eventBus,
  ) : super(SessionInitial()) {
    on<LoadSessions>(_onLoadSessions);
    on<DeleteSession>(_onDeleteSession);
    on<Logout>(_onLogout);
    on<SessionClosedExternally>(_onSessionClosedExternally);
  }

  void setupListeners() {
    closeSubs();

    _deleteSubscription = _eventBus.subscribe(
      table: tableName,
      action: ActionType.delete,
      onData: (event) async {
        final deletedId = event.data["id"];
        if (deletedId == null) return;

        final currentSessionId = await _sessionRepository.getCurrentSessionId();

        if (deletedId.toString() == currentSessionId?.toString()) {
          add(SessionClosedExternally());
          return;
        }
      },
    );
  }

  Future<void> _onLoadSessions(
    LoadSessions event,
    Emitter<SessionState> emit,
  ) async {
    emit(SessionLoading());

    final result = await _sessionRepository.get();

    result.fold(
      (failure) => emit(SessionFailure(failure)),
      (sessions) => emit(SessionLoaded(sessions)),
    );
  }

  Future<void> _onDeleteSession(
    DeleteSession event,
    Emitter<SessionState> emit,
  ) async {
    final result = await _sessionRepository.delete(event.id, event.type);

    result.fold(
      (failure) {
        emit(SessionFailure(failure));
      },
      (success) {
        if (state is SessionLoaded) {
          final currentSessions = (state as SessionLoaded).sessions;

          List<SessionModel> updatedSessions;
          if (event.type == ActionSessionType.others) {
            updatedSessions = currentSessions
                .where((s) => s.isCurrentSession)
                .toList();
          } else {
            updatedSessions = currentSessions
                .where((s) => s.id != event.id)
                .toList();
          }

          emit(SessionLoaded(updatedSessions));
        } else {
          add(LoadSessions());
        }
      },
    );
  }

  Future<void> _onLogout(Logout event, Emitter<SessionState> emit) async {
    emit(SessionLoading());

    final currentSessionId = await _sessionRepository.getCurrentSessionId();
    if (currentSessionId == null) {
      await _secureStorage.clearAll();
      emit(SessionLoggedOut());
      return;
    }

    final result = await _sessionRepository.delete(
      currentSessionId,
      ActionSessionType.target,
    );

    final failure = result.fold((l) => l, (r) => null);

    if (failure != null) {
      emit(SessionFailure(failure));
    } else {
      await _secureStorage.clearAll();
      emit(SessionLoggedOut());
    }
  }

  Future<void> _onSessionClosedExternally(
    SessionClosedExternally event,
    Emitter<SessionState> emit,
  ) async {
    if (emit.isDone) return;

    await _secureStorage.clearAll();

    if (!emit.isDone) {
      emit(SessionLoggedOut());
    }
  }

  @override
  Future<void> close() {
    closeSubs();
    _userRepository.clearCurrentUser();
    return super.close();
  }

  void closeSubs() {
    _deleteSubscription?.cancel();
  }
}

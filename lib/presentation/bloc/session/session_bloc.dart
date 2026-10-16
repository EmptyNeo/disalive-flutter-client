import 'dart:async';
import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:disalive/data/repositories/local_chat_state_repository.dart';
import 'package:disalive/domain/enums/action_session_type.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
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
  final LocalChatStateRepository _localChatStateRepository;

  StreamSubscription? _deleteSubscription;

  final String tableName = 'SessionUser';

  SessionBloc(
    this._userRepository,
    this._sessionRepository,
    this._secureStorage,
    this._eventBus,
    this._localChatStateRepository,
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
      await _clearLocalSession();
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
      await _clearLocalSession();
      emit(SessionLoggedOut());
    }
  }

  Future<void> _onSessionClosedExternally(
    SessionClosedExternally event,
    Emitter<SessionState> emit,
  ) async {
    if (emit.isDone) return;

    await _clearLocalSession();

    if (!emit.isDone) {
      emit(SessionLoggedOut());
    }
  }

  Future<void> _clearLocalSession() async {
    try {
      await _localChatStateRepository.clearDraftsForUser(
        _userRepository.getCurrentUser()?.id,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to clear local chat drafts on logout',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      await _secureStorage.clearAll();
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

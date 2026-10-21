import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/call_data.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/repositories/calls_repository.dart';
import 'package:equatable/equatable.dart';

part 'call_participants_event.dart';
part 'call_participants_state.dart';

class CallParticipantsBloc
    extends Bloc<CallParticipantsEvent, CallParticipantsState> {
  CallParticipantsBloc(this._repository)
    : super(const CallParticipantsState()) {
    on<WatchCallParticipants>(_onWatch);
    on<RefreshCallParticipants>(_onRefresh);
    on<StopWatchingCallParticipants>(_onStop);
  }

  final CallsRepository _repository;
  Timer? _timer;
  EntityKey? _entityKey;
  int? _chatId;
  int _generation = 0;
  int? _fetchingGeneration;

  void _onWatch(
    WatchCallParticipants event,
    Emitter<CallParticipantsState> emit,
  ) {
    _timer?.cancel();
    _entityKey = event.entityKey;
    _chatId = event.chatId;
    _generation++;
    emit(const CallParticipantsState(isLoading: true));
    add(const RefreshCallParticipants());
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!isClosed) add(const RefreshCallParticipants());
    });
  }

  Future<void> _onRefresh(
    RefreshCallParticipants event,
    Emitter<CallParticipantsState> emit,
  ) async {
    final entityKey = _entityKey;
    if (entityKey == null || _fetchingGeneration == _generation) return;
    final generation = _generation;
    _fetchingGeneration = generation;
    try {
      final result = await _repository.getParticipants(
        entityKey: entityKey,
        chatId: _chatId,
      );
      if (isClosed || generation != _generation) return;
      result.fold(
        (failure) => emit(CallParticipantsState(error: failure)),
        (participants) =>
            emit(CallParticipantsState(participants: participants)),
      );
    } finally {
      if (_fetchingGeneration == generation) _fetchingGeneration = null;
    }
  }

  void _onStop(
    StopWatchingCallParticipants event,
    Emitter<CallParticipantsState> emit,
  ) {
    _timer?.cancel();
    _entityKey = null;
    _chatId = null;
    _generation++;
    emit(const CallParticipantsState());
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await super.close();
  }
}

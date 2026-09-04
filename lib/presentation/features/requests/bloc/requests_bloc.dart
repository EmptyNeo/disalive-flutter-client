import 'package:bloc/bloc.dart';
import 'package:disalive/domain/models/friend_request.dart';
import 'package:disalive/domain/repositories/requests_repository.dart';
import 'package:flutter/cupertino.dart';

part 'requests_event.dart';

part 'requests_state.dart';

class RequestsBloc extends Bloc<RequestsEvent, RequestsState> {
  final RequestsRepository _friendsRepository;

  RequestsBloc(this._friendsRepository) : super(RequestsInitial()) {
    on<GetRequests>(_onGetRequests);
    on<SendRequest>(_onSendRequest);
    on<CancelRequest>(_onCancelRequest);
    on<AcceptRequest>(_onAcceptRequest);
  }

  Future<void> _onGetRequests(
    GetRequests event,
    Emitter<RequestsState> emit,
  ) async {
    emit(RequestsLoading());

    final result = await _friendsRepository.get();

    result.fold(
      (failure) => emit(RequestsFailure(failure.message)),
      (requests) => emit(RequestsLoaded(requests)),
    );
  }

  Future<void> _onSendRequest(
    SendRequest event,
    Emitter<RequestsState> emit,
  ) async {
    final result = await _friendsRepository.send(event.username);

    result.fold(
      (failure) {
        // Можно показать ошибку
        if (state is RequestsLoaded) {
          final currentState = state as RequestsLoaded;
          emit(RequestsLoaded(currentState.requests));
        }
      },
      (success) {
        // После отправки — обновляем список
        add(GetRequests());
      },
    );
  }

  Future<void> _onCancelRequest(
    CancelRequest event,
    Emitter<RequestsState> emit,
  ) async {
    final result = await _friendsRepository.cancel(event.username);

    result.fold(
      (failure) {
        if (state is RequestsLoaded) {
          final currentState = state as RequestsLoaded;
          emit(RequestsLoaded(currentState.requests));
        }
      },
      (success) {
        // Обновляем список из кэша репозитория
        if (state is RequestsLoaded) {
          List<FriendRequest> requests = _friendsRepository.getCached();
          emit(RequestsLoaded(requests));
        }
      },
    );
  }

  Future<void> _onAcceptRequest(
    AcceptRequest event,
    Emitter<RequestsState> emit,
  ) async {
    final result = await _friendsRepository.accept(event.username);

    result.fold(
      (failure) {
        if (state is RequestsLoaded) {
          final currentState = state as RequestsLoaded;
          emit(RequestsLoaded(currentState.requests));
        }
      },
      (success) {
        // После принятия — обновляем список
        if (state is RequestsLoaded) {
          List<FriendRequest> requests = _friendsRepository.getCached();
          emit(RequestsLoaded(requests));
        }
      },
    );
  }
}

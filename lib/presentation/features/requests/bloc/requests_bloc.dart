import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/friend_request.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/requests_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:flutter/cupertino.dart';

part 'requests_event.dart';

part 'requests_state.dart';

class RequestsBloc extends Bloc<RequestsEvent, RequestsState> {
  final RequestsRepository _friendsRepository;
  final WsEventBus _eventBus;

  StreamSubscription<WsEvent>? _createSubscription;
  StreamSubscription<WsEvent>? _deleteSubscription;

  final _errorStreamController = StreamController<String>.broadcast();

  Stream<String> get errorStream => _errorStreamController.stream;

  RequestsBloc(this._friendsRepository, this._eventBus)
    : super(RequestsInitial()) {
    on<GetRequests>(_onGetRequests);
    on<SendRequest>(_onSendRequest);
    on<CancelRequest>(_onCancelRequest);
    on<AcceptRequest>(_onAcceptRequest);
    on<AddRequest>(_onAddRequest);
    on<RemoveRequest>(_onRemoveRequest);

    _setupWsListeners();
  }

  void _setupWsListeners() {
    // Создание запроса в друзья (когда кто-то отправил тебе)
    _createSubscription = _eventBus.subscribe(
      table: 'FriendRequest',
      action: ActionType.create,
      onData: (event) {
        final requestData = event.data['request'];
        if (requestData is Map<String, dynamic>) {
          final request = FriendRequest.fromMap(requestData);
          add(AddRequest(request));
        }
      },
    );

    // Удаление запроса (когда отменили или приняли)
    _deleteSubscription = _eventBus.subscribe(
      table: 'FriendRequest',
      action: ActionType.delete,
      onData: (event) {
        final requestId = event.data['requestId'] ?? event.data['id'];
        if (requestId != null) {
          add(RemoveRequest(requestId));
        }
      },
    );
  }

  void _onAddRequest(AddRequest event, Emitter<RequestsState> emit) {
    final requests = _friendsRepository.getCached();

    // Проверяем, нет ли уже такого запроса
    final exists = requests.any((r) => r.id == event.request.id);
    if (!exists) {
      requests.insert(0, event.request); // В начало списка
    }

    emit(RequestsLoaded(requests));
  }

  void _onRemoveRequest(RemoveRequest event, Emitter<RequestsState> emit) {
    final requests = _friendsRepository.getCached();

    requests.removeWhere((r) => r.id == event.requestId);

    emit(RequestsLoaded(requests));
  }

  Future<void> _onGetRequests(
    GetRequests event,
    Emitter<RequestsState> emit,
  ) async {
    emit(RequestsLoading());

    final cached = _friendsRepository.getCached();

    if (cached.isNotEmpty && event.reload == false) {
      emit(RequestsLoaded(cached));
      return;
    }

    final result = await _friendsRepository.get();

    result.fold(
      (failure) => emit(RequestsFailure(failure)),
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
        _errorStreamController.add(failure.message);
      },
      (success) {
        List<FriendRequest> requests = _friendsRepository.getCached();
        emit(RequestsLoaded(requests));
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
        _errorStreamController.add(failure.message);
      },
      (success) {
        List<FriendRequest> requests = _friendsRepository.getCached();
        emit(RequestsLoaded(requests));
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
        _errorStreamController.add(failure.message);
      },
      (success) {
        List<FriendRequest> requests = _friendsRepository.getCached();
        emit(RequestsLoaded(requests));
      },
    );
  }

  @override
  Future<void> close() {
    _createSubscription?.cancel();
    _deleteSubscription?.cancel();
    _errorStreamController.close();
    return super.close();
  }
}

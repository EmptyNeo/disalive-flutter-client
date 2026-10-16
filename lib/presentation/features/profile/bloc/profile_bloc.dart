// lib/presentation/features/profile/bloc/profile_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/user_response_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter/cupertino.dart';

part 'profile_event.dart';

part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository _userRepository;
  final AuthBloc _authBloc;
  final WsEventBus _eventBus;

  StreamSubscription<WsEvent>? _userUpdateSubscription;
  final _errorStreamController = StreamController<Failure>.broadcast();

  Stream<Failure> get errorStream => _errorStreamController.stream;

  ProfileBloc(this._userRepository, this._authBloc, this._eventBus)
    : super(ProfileInitial()) {
    on<GetProfile>(_onGetProfile);
    on<ClearProfile>(_onClearProfile);
    on<UpdateCurrentUser>(_onUpdateCurrentUser);
    on<GetProfileByUsername>(_onGetProfileByUsername);
    on<UpdateProfile>(_onUpdateProfile);
  }

  void setupListeners() {
    closeSubs();

    _userUpdateSubscription = _eventBus.subscribe(
      table: 'User',
      action: ActionType.update,
      onData: (event) {
        final map = event.data['user'];
        if (map is Map<String, dynamic>) {
          final updatedUser = UserModel.fromMap(map);
          add(UpdateCurrentUser(updatedUser));
        }
      },
    );
  }

  Future<void> _onGetProfile(
    GetProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    if (event.userResponseType == UserResponseType.user) {
      final cachedUser = _userRepository.getCurrentUser();
      if (cachedUser != null) {
        emit(ProfileLoaded(cachedUser));
        return;
      }
    }

    final result = await _userRepository.get(
      event.userResponseType,
      event.username,
      onUnauthorized: () {
        _authBloc.add(AuthLogout());
      },
    );

    result.fold(
      (failure) {
        if (failure is UnauthorizedFailure) {
          emit(AuthLogoutState());
        } else {
          emit(ProfileFailure(failure));
        }
      },
      (user) {
        if (event.userResponseType == UserResponseType.user) {
          _userRepository.setCurrentUser(user);
        }
        emit(ProfileLoaded(user));
      },
    );
  }

  Future<void> _onGetProfileByUsername(
    GetProfileByUsername event,
    Emitter<ProfileState> emit,
  ) async {
    if (event.initialUser != null) {
      emit(ProfileLoaded(event.initialUser!));
    } else {
      emit(ProfileLoading());
    }

    final result = await _userRepository.get(
      UserResponseType.profile,
      event.username,
      onUnauthorized: () {
        _authBloc.add(AuthLogout());
      },
    );

    result.fold(
      (failure) {
        if (failure is UnauthorizedFailure) {
          emit(AuthLogoutState());
        } else {
          if (event.initialUser == null) {
            emit(ProfileFailure(failure));
          }
        }
      },
      (user) {
        emit(ProfileLoaded(user));
      },
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;

    final startState = state as ProfileLoaded;
    final newLoadingFields = Set<String>.from(startState.loadingFields);

    if (event.loadingField != null) {
      newLoadingFields.add(event.loadingField!);
    }
    emit(startState.copyWith(loadingFields: newLoadingFields));

    final result = await _userRepository.update(event.updateUser);

    final liveState = state;
    if (liveState is! ProfileLoaded) return;

    result.fold(
      (failure) {
        // 🎯 1. ОТПРАВЛЯЕМ ОШИБКУ В СТРИМ
        _errorStreamController.add(failure);

        // 🎯 2. ОСТАВЛЯЕМ СОСТОЯНИЕ LOADED, но убираем флаг загрузки
        final revertedLoading = Set<String>.from(liveState.loadingFields);
        if (event.loadingField != null) {
          revertedLoading.remove(event.loadingField!);
        }
        emit(liveState.copyWith(loadingFields: revertedLoading));
      },
      (updatedUser) {
        _userRepository.setCurrentUser(updatedUser);

        final successLoading = Set<String>.from(liveState.loadingFields);
        if (event.loadingField != null) {
          successLoading.remove(event.loadingField!);
        }
        emit(ProfileLoaded(updatedUser, loadingFields: successLoading));
      },
    );
  }

  Future<void> _onUpdateCurrentUser(
    UpdateCurrentUser event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;

    if (currentState.user.id != event.user.id) {
      return;
    }

    _userRepository.setCurrentUser(event.user);

    emit(ProfileLoaded(event.user));
  }

  Future<void> _onClearProfile(
    ClearProfile event,
    Emitter<ProfileState> emit,
  ) async {
    _userRepository.clearCurrentUser();
    emit(ProfileInitial());
  }

  void closeSubs() {
    _userUpdateSubscription?.cancel();
  }

  @override
  Future<void> close() {
    closeSubs();
    _errorStreamController.close();
    return super.close();
  }
}

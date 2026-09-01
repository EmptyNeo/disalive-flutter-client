// lib/presentation/features/profile/bloc/profile_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/user_response_type.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter/cupertino.dart';

part 'profile_event.dart';

part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository _userRepository;
  final AuthBloc _authBloc;

  ProfileBloc(this._userRepository, this._authBloc) : super(ProfileInitial()) {
    on<GetProfile>(_onGetProfile);
    on<ClearProfile>(_onClearProfile);
  }

  Future<void> _onGetProfile(
    GetProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    if (event.userResponseType == UserResponseType.USER) {
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
        emit(ProfileFailure(failure.message));
      },
      (user) {
        if (event.userResponseType == UserResponseType.USER) {
          _userRepository.setCurrentUser(user);
        }
        emit(ProfileLoaded(user));
      },
    );
  }

  Future<void> _onClearProfile(
    ClearProfile event,
    Emitter<ProfileState> emit,
  ) async {
    _userRepository.clearCurrentUser();
    emit(ProfileInitial());
  }
}

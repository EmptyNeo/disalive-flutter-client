import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:disalive/domain/repositories/auth_repository.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:flutter/cupertino.dart';

part 'auth_event.dart';

part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  AuthBloc(this._authRepository, this._userRepository) : super(AuthInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<AuthLogout>(_onLogout);
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authRepository.login(event.email, event.password);

    result.fold(
      (failure) {
        emit(AuthFailure(error: failure.message));
      },
      (appLogin) {
        if (appLogin.requireTotp) {
          emit(AuthTotpRequired());
        } else {
          emit(AuthAuthenticated());
        }
      },
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authRepository.checkAuth();

    result.fold((failure) => emit(AuthUnauthenticated()), (isAuthenticated) {
      if (isAuthenticated) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> _onLogout(
    AuthLogout event,
    Emitter<AuthState> emit,
  ) async {
    _userRepository.clearCurrentUser();
    emit(AuthUnauthenticated());
  }
}

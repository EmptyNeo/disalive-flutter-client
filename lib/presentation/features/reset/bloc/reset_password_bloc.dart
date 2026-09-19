import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/email_type.dart';
import 'package:disalive/domain/repositories/email_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:equatable/equatable.dart';

part 'reset_password_event.dart';

part 'reset_password_state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final UserRepository _userRepository;
  final EmailRepository
  _emailRepository; // 🎯 Добавляем репозиторий для отправки почты

  ResetPasswordBloc(this._userRepository, this._emailRepository)
    : super(const ResetPasswordState()) {
    on<ResetEmailChanged>(_onEmailChanged);
    on<ResetEmailSubmitted>(_onEmailSubmitted);
    on<ResetNewPasswordChanged>(_onNewPasswordChanged);
    on<ResetVerifyPasswordChanged>(_onVerifyPasswordChanged);
    on<ResetSubmitPressed>(_onSubmitPressed);
    on<ResetGoBack>(_onGoBack);
    on<ResetReset>(_onReset);
  }

  void _onEmailChanged(
    ResetEmailChanged event,
    Emitter<ResetPasswordState> emit,
  ) {
    emit(state.copyWith(email: event.email, emailError: null));
  }

  Future<void> _onEmailSubmitted(
    ResetEmailSubmitted event,
    Emitter<ResetPasswordState> emit,
  ) async {
    if (state.email.isEmpty || !state.email.contains('@')) {
      emit(state.copyWith(emailError: 'Введите корректный email'));
      return;
    }

    emit(state.copyWith(isLoading: true, emailError: null));

    final result = await _userRepository.hasExistingData(null, state.email);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isLoading: false,
            emailError: 'Ошибка сети. Попробуйте позже.',
          ),
        );
      },
      (exists) {
        if (!exists) {
          emit(
            state.copyWith(
              isLoading: false,
              emailError: 'Пользователь с таким email не найден',
            ),
          );
        } else {
          emit(
            state.copyWith(
              isLoading: false,
              currentStep: 2, // Переход к шагу с паролями
            ),
          );
        }
      },
    );
  }

  void _onNewPasswordChanged(
    ResetNewPasswordChanged event,
    Emitter<ResetPasswordState> emit,
  ) {
    emit(state.copyWith(newPassword: event.password, passwordError: null));
  }

  void _onVerifyPasswordChanged(
    ResetVerifyPasswordChanged event,
    Emitter<ResetPasswordState> emit,
  ) {
    emit(state.copyWith(verifyPassword: event.password, passwordError: null));
  }

  // 🎯 ИСПРАВЛЕННЫЙ МЕТОД: теперь он асинхронный и реально отправляет код
  Future<void> _onSubmitPressed(
    ResetSubmitPressed event,
    Emitter<ResetPasswordState> emit,
  ) async {
    if (state.newPassword.length < 6) {
      emit(
        state.copyWith(passwordError: 'Пароль должен быть не менее 6 символов'),
      );
      return;
    }

    if (state.newPassword != state.verifyPassword) {
      emit(state.copyWith(passwordError: 'Пароли не совпадают'));
      return;
    }

    // Включаем индикатор загрузки на кнопке
    emit(state.copyWith(isLoading: true, passwordError: null));

    // 🎯 РЕАЛЬНАЯ ОТПРАВКА КОДА НА ПОЧТУ
    final result = await _emailRepository.sendVerificationEmail(
      email: state.email,
      type: EmailType.reset,
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isLoading: false,
            passwordError: 'Не удалось отправить код. Попробуйте позже.',
          ),
        );
      },
      (success) {
        // Если код успешно отправлен, разрешаем переход на экран подтверждения
        emit(state.copyWith(isLoading: false, isReadyToVerify: true));
      },
    );
  }

  void _onGoBack(ResetGoBack event, Emitter<ResetPasswordState> emit) {
    if (state.currentStep == 1) return;
    emit(state.copyWith(currentStep: 1, passwordError: null));
  }

  void _onReset(ResetReset event, Emitter<ResetPasswordState> emit) {
    emit(
      ResetPasswordState(
        email: event.email,
        newPassword: event.newPassword,
        verifyPassword: event.verifyPassword,
      ),
    );
  }
}

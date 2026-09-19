import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/email_type.dart';
import 'package:disalive/domain/repositories/email_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:equatable/equatable.dart';

part 'verify_code_event.dart';

part 'verify_code_state.dart';

class VerifyCodeBloc extends Bloc<VerifyCodeEvent, VerifyCodeState> {
  final UserRepository _userRepository;
  final EmailRepository _emailRepository;
  Timer? _resendTimer;

  VerifyCodeBloc(this._userRepository, this._emailRepository)
    : super(const VerifyCodeState()) {
    on<VerifyCodeInit>(_onInit);
    on<VerifyCodeDigitChanged>(_onDigitChanged);
    on<VerifyCodePasted>(_onCodePasted);
    on<VerifyCodePressed>(_onVerifyPressed);
    on<ResendCodePressed>(_onResendPressed);
    on<TimerTick>(_onTimerTick);
    on<VerifyCodeReset>(_onReset);
  }

  Future<void> _onInit(
    VerifyCodeInit event,
    Emitter<VerifyCodeState> emit,
  ) async {
    emit(
      state.copyWith(
        email: event.email,
        emailType: event.emailType,
        newPassword: event.newPassword,
        verifyPassword: event.verifyPassword,
        username: event.username,
        displayName: event.displayName,
        password: event.password,
        resendTimer: 60,
      ),
    );
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendTimer > 0) {
        add(TimerTick());
      } else {
        timer.cancel();
      }
    });
  }

  void _onDigitChanged(
    VerifyCodeDigitChanged event,
    Emitter<VerifyCodeState> emit,
  ) {
    final newDigits = List<String>.from(state.codeDigits);
    newDigits[event.index] = event.digit;
    emit(state.copyWith(codeDigits: newDigits, error: null));

    final isComplete = newDigits.every((d) => d.isNotEmpty);

    if (isComplete) {
      Future.delayed(const Duration(milliseconds: 400), () {
        add(VerifyCodePressed());
      });
    }
  }

  void _onCodePasted(VerifyCodePasted event, Emitter<VerifyCodeState> emit) {
    final code = event.code.replaceAll(RegExp(r'\D'), '');
    if (code.length == 6) {
      emit(state.copyWith(codeDigits: code.split(''), error: null));
      Future.delayed(const Duration(milliseconds: 400), () {
        add(VerifyCodePressed());
      });
    }
  }

  Future<void> _onVerifyPressed(
    VerifyCodePressed event,
    Emitter<VerifyCodeState> emit,
  ) async {
    if (!state.isCodeComplete) {
      emit(state.copyWith(error: 'Введите все 6 цифр кода'));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));
    final code = state.fullCode;

    try {
      if (state.emailType == EmailType.confirmRegister) {
        final result = await _userRepository.create(
          state.email,
          state.displayName,
          state.username,
          state.password,
          code,
        );

        result.fold(
          (failure) =>
              emit(state.copyWith(isLoading: false, error: failure.message)),
          (success) => emit(state.copyWith(isLoading: false, isSuccess: true)),
        );
      } else if (state.emailType == EmailType.reset) {
        if (state.newPassword == null || state.verifyPassword == null) {
          emit(state.copyWith(isLoading: false, error: 'Ошибка данных'));
          return;
        }

        final result = await _userRepository.resetPassword(
          state.email,
          code,
          state.newPassword!,
          state.verifyPassword!,
        );

        result.fold(
          (failure) =>
              emit(state.copyWith(isLoading: false, error: failure.message)),
          (success) => emit(state.copyWith(isLoading: false, isSuccess: true)),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Ошибка сети. Попробуйте позже.',
        ),
      );
    }
  }

  Future<void> _onResendPressed(
    ResendCodePressed event,
    Emitter<VerifyCodeState> emit,
  ) async {
    emit(state.copyWith(resendTimer: 60, isLoading: true, error: null));
    _startResendTimer();

    final result = await _emailRepository.sendVerificationEmail(
      email: event.email,
      type: event.emailType,
      username: event.username,
      password: event.password,
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isLoading: false,
            error: 'Не удалось отправить код. Попробуйте позже.',
          ),
        );
      },
      (success) {
        emit(state.copyWith(isLoading: false));
      },
    );
  }

  void _onTimerTick(TimerTick event, Emitter<VerifyCodeState> emit) {
    if (state.resendTimer > 0) {
      emit(state.copyWith(resendTimer: state.resendTimer - 1));
    }
  }

  void _onReset(VerifyCodeReset event, Emitter<VerifyCodeState> emit) {
    emit(
      VerifyCodeState(
        email: state.email,
        emailType: state.emailType,
        newPassword: state.newPassword,
        verifyPassword: state.verifyPassword,
      ),
    );
  }

  @override
  Future<void> close() {
    _resendTimer?.cancel();
    return super.close();
  }
}

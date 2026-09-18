import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/email_type.dart';
import 'package:disalive/domain/repositories/email_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:equatable/equatable.dart';

part 'register_event.dart';

part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final UserRepository _userRepository;
  final EmailRepository _emailRepository;

  Timer? _debounceTimer;

  RegisterBloc(this._userRepository, this._emailRepository)
    : super(const RegisterState()) {
    on<RegisterEmailChanged>(_onEmailChanged);
    on<RegisterEmailSubmitted>(_onEmailSubmitted);
    on<RegisterDisplayNameChanged>(_onDisplayNameChanged);
    on<RegisterDisplayNameSubmitted>(_onDisplayNameSubmitted);
    on<RegisterUsernameChanged>(_onUsernameChanged);
    on<RegisterUsernameCheck>(_onUsernameCheck);
    on<RegisterPasswordChanged>(_onPasswordChanged);
    on<RegisterSubmitPressed>(_onSubmitPressed);
    on<RegisterReset>(_onReset);
    on<RegisterGoBack>(_onGoBack);
  }

  void _onEmailChanged(
    RegisterEmailChanged event,
    Emitter<RegisterState> emit,
  ) {
    emit(state.copyWith(email: event.email, emailError: null));
  }

  Future<void> _onEmailSubmitted(
    RegisterEmailSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    if (state.email.isEmpty || !state.email.contains('@')) {
      emit(state.copyWith(emailError: 'Введите корректный email'));
      return;
    }

    emit(state.copyWith(isEmailLoading: true, emailError: null));

    final result = await _userRepository.hasExistingData(null, state.email);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isEmailLoading: false,
            emailError: 'Ошибка сети. Попробуйте позже.',
          ),
        );
      },
      (hasExisting) {
        if (hasExisting) {
          emit(
            state.copyWith(
              isEmailLoading: false,
              emailError: 'Этот email уже зарегистрирован',
            ),
          );
        } else {
          emit(
            state.copyWith(
              isEmailLoading: false,
              currentStep: 2, // Переход к шагу 2
            ),
          );
        }
      },
    );
  }

  void _onDisplayNameChanged(
    RegisterDisplayNameChanged event,
    Emitter<RegisterState> emit,
  ) {
    emit(state.copyWith(displayName: event.displayName));
  }

  void _onDisplayNameSubmitted(
    RegisterDisplayNameSubmitted event,
    Emitter<RegisterState> emit,
  ) {
    if (state.displayName.trim().isEmpty) {
      return; // Можно добавить визуальную подсказку, но по ТЗ проверки нет
    }

    // 🎯 Автоматически генерируем username и переходим к шагу 3
    final generatedUsername = _generateUsername(state.displayName);
    emit(state.copyWith(currentStep: 3, username: generatedUsername));
  }

  void _onUsernameChanged(
    RegisterUsernameChanged event,
    Emitter<RegisterState> emit,
  ) {
    emit(state.copyWith(username: event.username, usernameError: null));

    _debounceTimer?.cancel();

    if (event.username.trim().isNotEmpty) {
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        add(RegisterUsernameCheck());
      });
    }
  }

  Future<void> _onUsernameCheck(
    RegisterUsernameCheck event,
    Emitter<RegisterState> emit,
  ) async {
    // 🎯 5. Отменяем таймер, так как проверка инициирована вручную (например, при переходе к паролю)
    _debounceTimer?.cancel();

    final cleanUsername = state.username.trim();
    if (cleanUsername.isEmpty) {
      emit(state.copyWith(usernameError: 'Введите имя пользователя'));
      return;
    }

    // Если уже загружается или имя не менялось с последней успешной проверки, можно не делать запрос (оптимизация)
    if (state.isUsernameLoading) return;

    emit(state.copyWith(isUsernameLoading: true, usernameError: null));

    final result = await _userRepository.hasExistingData(cleanUsername, null);

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isUsernameLoading: false,
            usernameError: 'Ошибка сети. Попробуйте позже.',
          ),
        );
      },
      (hasExisting) {
        if (hasExisting) {
          emit(
            state.copyWith(
              isUsernameLoading: false,
              usernameError: 'Это имя пользователя уже занято',
            ),
          );
        } else {
          emit(
            state.copyWith(
              isUsernameLoading: false,
              // usernameError остаётся null (успех)
            ),
          );
        }
      },
    );
  }

  void _onPasswordChanged(
    RegisterPasswordChanged event,
    Emitter<RegisterState> emit,
  ) {
    emit(state.copyWith(password: event.password, generalError: null));
  }

  void _onGoBack(RegisterGoBack event, Emitter<RegisterState> emit) {
    if (state.currentStep == 1) {
      return;
    }

    emit(
      state.copyWith(
        currentStep: state.currentStep - 1,
        emailError: null,
        usernameError: null,
        generalError: null,
      ),
    );
  }

  Future<void> _onSubmitPressed(
    RegisterSubmitPressed event,
    Emitter<RegisterState> emit,
  ) async {
    // 1. Валидация пароля
    if (state.password.length < 6) {
      emit(
        state.copyWith(generalError: 'Пароль должен быть не менее 6 символов'),
      );
      return;
    }

    // 2. Если имя пользователя ещё не проверено или занято, проверяем его прямо сейчас
    if (state.usernameError != null || state.isUsernameLoading) {
      add(RegisterUsernameCheck());
      // Примечание: в реальном UI лучше не давать нажать кнопку, пока isUsernameLoading == true
      // или usernameError != null, но эта страховка не помешает.
      return;
    }

    emit(state.copyWith(isSubmitLoading: true, generalError: null));

    // 3. Отправка кода на email
    final result = await _emailRepository.sendVerificationEmail(
      email: state.email,
      type: EmailType.confirmRegister,
      username: state.displayName,
      password: state.password,
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isSubmitLoading: false,
            generalError: 'Не удалось отправить код. Попробуйте позже.',
          ),
        );
      },
      (success) {
        emit(state.copyWith(isSubmitLoading: false));
        // 🎯 Здесь UI через BlocListener должен увидеть успех и сделать навигацию на экран ввода кода
      },
    );
  }

  void _onReset(RegisterReset event, Emitter<RegisterState> emit) {
    emit(const RegisterState());
  }

  // 🎯 Хелпер для генерации username
  String _generateUsername(String displayName) {
    if (displayName.trim().isEmpty) return '';

    const Map<String, String> translitMap = {
      'а': 'a',
      'б': 'b',
      'в': 'v',
      'г': 'g',
      'д': 'd',
      'е': 'e',
      'ё': 'yo',
      'ж': 'zh',
      'з': 'z',
      'и': 'i',
      'й': 'y',
      'к': 'k',
      'л': 'l',
      'м': 'm',
      'н': 'n',
      'о': 'o',
      'п': 'p',
      'р': 'r',
      'с': 's',
      'т': 't',
      'у': 'u',
      'ф': 'f',
      'х': 'h',
      'ц': 'ts',
      'ч': 'ch',
      'ш': 'sh',
      'щ': 'sch',
      'ъ': '',
      'ы': 'y',
      'ь': '',
      'э': 'e',
      'ю': 'yu',
      'я': 'ya',
    };

    String lowerName = displayName.toLowerCase().trim();
    String transliterated = '';

    for (int i = 0; i < lowerName.length; i++) {
      String char = lowerName[i];
      if (char == ' ') {
        transliterated += '_';
      } else {
        transliterated += translitMap[char] ?? char;
      }
    }

    // Убираем все недопустимые символы (оставляем только a-z, 0-9 и _)
    transliterated = transliterated.replaceAll(RegExp(r'[^a-z0-9_]'), '');

    // Если после очистки строка пустая, используем дефолтное значение
    if (transliterated.isEmpty) transliterated = 'user';

    // Добавляем "_" и 3 случайные цифры (от 100 до 999)
    final randomDigits = Random().nextInt(900) + 100;

    return '${transliterated}_$randomDigits';
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

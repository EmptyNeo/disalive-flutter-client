// lib/domain/failures/failures.dart
abstract class Failure {
  final String message;

  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('Отсутствует интернет-соединение.');
}

class ServerFailure extends Failure {
  const ServerFailure([String? message])
    : super(message ?? 'Ошибка сервера. Попробуйте позже.');
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('Сессия истекла. Войдите заново.');
}

class ClientFailure extends Failure {
  ClientFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([String? message])
    : super(message ?? 'Cache error occurred');
}

class ParsingFailure extends Failure {
  const ParsingFailure([String? message])
    : super(message ?? 'Ошибка обработки данных');
}

class ValidationFailure extends Failure {
  final Map<dynamic, dynamic> errors;

  const ValidationFailure(this.errors) : super('Ошибка валидации данных');
}

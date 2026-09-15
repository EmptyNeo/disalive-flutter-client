part of 'session_bloc.dart';

abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSessions extends SessionEvent {}

class DeleteSession extends SessionEvent {
  final int id;
  final ActionSessionType type;

  const DeleteSession({required this.id, required this.type});

  @override
  List<Object?> get props => [id, type];
}

class Logout extends SessionEvent {}

// 🎯 Специальное событие для WebSocket: когда сессию закрыли с другого устройства
class SessionClosedExternally extends SessionEvent {}

part of 'session_bloc.dart';

abstract class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

class SessionInitial extends SessionState {}

class SessionLoading extends SessionState {}

class SessionLoaded extends SessionState {
  final List<SessionModel> sessions;

  const SessionLoaded(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

class SessionFailure extends SessionState {
  final Failure error;

  const SessionFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class SessionLoggedOut extends SessionState {}
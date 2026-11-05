part of 'server_deletion_bloc.dart';

sealed class ServerDeletionEvent extends Equatable {
  const ServerDeletionEvent();

  @override
  List<Object?> get props => [];
}

class RequestServerDeletionCode extends ServerDeletionEvent {
  const RequestServerDeletionCode();
}

class ConfirmServerDeletion extends ServerDeletionEvent {
  const ConfirmServerDeletion(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

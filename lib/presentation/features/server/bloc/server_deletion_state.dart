part of 'server_deletion_bloc.dart';

class ServerDeletionState extends Equatable {
  const ServerDeletionState({
    this.method,
    this.loading = false,
    this.submitting = false,
    this.completed = false,
    this.error,
  });

  final String? method;
  final bool loading;
  final bool submitting;
  final bool completed;
  final String? error;

  @override
  List<Object?> get props => [method, loading, submitting, completed, error];
}

part of 'call_participants_bloc.dart';

class CallParticipantsState extends Equatable {
  const CallParticipantsState({
    this.participants = const CallParticipants({}),
    this.isLoading = false,
    this.error,
  });

  final CallParticipants participants;
  final bool isLoading;
  final Failure? error;

  bool hasParticipants(int chatId) => participants.forChat(chatId).isNotEmpty;

  @override
  List<Object?> get props => [participants, isLoading, error];
}

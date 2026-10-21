part of 'call_participants_bloc.dart';

sealed class CallParticipantsEvent extends Equatable {
  const CallParticipantsEvent();

  @override
  List<Object?> get props => [];
}

class WatchCallParticipants extends CallParticipantsEvent {
  const WatchCallParticipants(this.entityKey, {this.chatId});

  final EntityKey entityKey;
  final int? chatId;

  @override
  List<Object?> get props => [entityKey, chatId];
}

class RefreshCallParticipants extends CallParticipantsEvent {
  const RefreshCallParticipants();
}

class StopWatchingCallParticipants extends CallParticipantsEvent {
  const StopWatchingCallParticipants();
}

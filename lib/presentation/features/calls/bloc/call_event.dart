part of 'call_bloc.dart';

sealed class CallEvent extends Equatable {
  const CallEvent();
  @override
  List<Object?> get props => [];
}

class JoinCall extends CallEvent {
  const JoinCall({
    required this.chatId,
    required this.entityKey,
    required this.title,
    this.lastIdMessage,
    this.announceCall = true,
  });
  final int chatId;
  final EntityKey entityKey;
  final String title;
  final int? lastIdMessage;
  final bool announceCall;
  @override
  List<Object?> get props => [
    chatId,
    entityKey,
    title,
    lastIdMessage,
    announceCall,
  ];
}

class DismissIncomingCall extends CallEvent {
  const DismissIncomingCall();
}

class _IncomingCallSignal extends CallEvent {
  const _IncomingCallSignal(this.call);
  final IncomingCall call;
}

class LeaveCall extends CallEvent {
  const LeaveCall();
}

class ToggleCallMicrophone extends CallEvent {
  const ToggleCallMicrophone();
}

class ToggleCallCamera extends CallEvent {
  const ToggleCallCamera();
}

class SwitchCallCamera extends CallEvent {
  const SwitchCallCamera();
}

class ToggleCallOutput extends CallEvent {
  const ToggleCallOutput();
}

class ToggleCallScreenShare extends CallEvent {
  const ToggleCallScreenShare();
}

class ToggleParticipantAudio extends CallEvent {
  const ToggleParticipantAudio(this.identity);
  final String identity;
  @override
  List<Object?> get props => [identity];
}

class PlayCallSound extends CallEvent {
  const PlayCallSound(this.path);
  final String path;
  @override
  List<Object?> get props => [path];
}

class _RoomChanged extends CallEvent {
  const _RoomChanged({this.syncAudio = false});
  final bool syncAudio;
  @override
  List<Object?> get props => [syncAudio];
}

class _RoomDisconnected extends CallEvent {
  const _RoomDisconnected();
}

class _CallDataReceived extends CallEvent {
  const _CallDataReceived(this.event);
  final lk.DataReceivedEvent event;
}

part of 'call_bloc.dart';

enum CallStatus { idle, connecting, connected, leaving, left, failed }

/// AUDIO означает карточку участника без видео; CAMERA и SCREENSHARE —
/// соответствующие опубликованные LiveKit источники.
enum CallTrackType { audio, camera, screenshare }

class IncomingCall extends Equatable {
  const IncomingCall({
    required this.chatId,
    required this.displayName,
    this.username,
    this.pathImage,
    this.isNsfw = false,
    this.streamType = 'audio',
  });

  final int chatId;
  final String displayName;
  final String? username;
  final String? pathImage;
  final bool isNsfw;
  final String streamType;

  @override
  List<Object?> get props => [
    chatId,
    displayName,
    username,
    pathImage,
    isNsfw,
    streamType,
  ];
}

class CallState extends Equatable {
  const CallState({
    this.status = CallStatus.idle,
    this.chatId,
    this.entityKey,
    this.title,
    this.room,
    this.microphoneEnabled = false,
    this.cameraEnabled = false,
    this.screenShareEnabled = false,
    this.outputEnabled = true,
    this.cameraPosition = lk.CameraPosition.front,
    this.locallyMutedParticipants = const {},
    this.headsetStates = const {},
    this.error,
    this.incomingCall,
    this.revision = 0,
  });
  final CallStatus status;
  final int? chatId;
  final EntityKey? entityKey;
  final String? title;
  final lk.Room? room;
  final bool microphoneEnabled;
  final bool cameraEnabled;
  final bool screenShareEnabled;
  final bool outputEnabled;
  final lk.CameraPosition cameraPosition;
  final Set<String> locallyMutedParticipants;
  final Map<String, bool> headsetStates;
  final String? error;
  final IncomingCall? incomingCall;
  final int revision;

  CallState copyWith({
    CallStatus? status,
    int? chatId,
    EntityKey? entityKey,
    String? title,
    lk.Room? room,
    bool? microphoneEnabled,
    bool? cameraEnabled,
    bool? screenShareEnabled,
    bool? outputEnabled,
    lk.CameraPosition? cameraPosition,
    Set<String>? locallyMutedParticipants,
    Map<String, bool>? headsetStates,
    String? error,
    IncomingCall? incomingCall,
    bool clearIncomingCall = false,
    int? revision,
  }) => CallState(
    status: status ?? this.status,
    chatId: chatId ?? this.chatId,
    entityKey: entityKey ?? this.entityKey,
    title: title ?? this.title,
    room: room ?? this.room,
    microphoneEnabled: microphoneEnabled ?? this.microphoneEnabled,
    cameraEnabled: cameraEnabled ?? this.cameraEnabled,
    screenShareEnabled: screenShareEnabled ?? this.screenShareEnabled,
    outputEnabled: outputEnabled ?? this.outputEnabled,
    cameraPosition: cameraPosition ?? this.cameraPosition,
    locallyMutedParticipants:
        locallyMutedParticipants ?? this.locallyMutedParticipants,
    headsetStates: headsetStates ?? this.headsetStates,
    error: error,
    incomingCall: clearIncomingCall ? null : incomingCall ?? this.incomingCall,
    revision: revision ?? this.revision,
  );

  @override
  List<Object?> get props => [
    status,
    chatId,
    entityKey,
    title,
    room,
    microphoneEnabled,
    cameraEnabled,
    screenShareEnabled,
    outputEnabled,
    cameraPosition,
    locallyMutedParticipants,
    headsetStates,
    error,
    incomingCall,
    revision,
  ];
}

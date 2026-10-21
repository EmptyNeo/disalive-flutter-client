import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/enums/user_status.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/calls_repository.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/chat_server_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/calls/pip_service.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:permission_handler/permission_handler.dart';

part 'call_event.dart';
part 'call_state.dart';

/// Управляет одной активной комнатой в области HomeScreen.
class CallBloc extends Bloc<CallEvent, CallState> {
  CallBloc(
    this._repository,
    this._chatServerRepository,
    this._eventBus,
    this._chatRepository,
    this._userRepository,
  ) : super(const CallState()) {
    on<JoinCall>(_onJoin);
    on<LeaveCall>(_onLeave);
    on<ToggleCallMicrophone>(_onMicrophone);
    on<ToggleCallCamera>(_onCamera);
    on<SwitchCallCamera>(_onSwitchCamera);
    on<ToggleCallOutput>(_onOutput);
    on<ToggleCallScreenShare>(_onScreenShare);
    on<ToggleParticipantAudio>(_onParticipantAudio);
    on<PlayCallSound>(_onPlaySound);
    on<_RoomChanged>(_onRoomChanged);
    on<_CallDataReceived>(_onDataReceived);
    on<_RoomDisconnected>(_onDisconnected);
    on<_IncomingCallSignal>(_onIncomingCall);
    on<DismissIncomingCall>((event, emit) {
      emit(state.copyWith(clearIncomingCall: true));
    });
  }

  static const liveKitUrl = 'wss://livekit.disalive.ru:4443';
  final CallsRepository _repository;
  final ChatServerRepository _chatServerRepository;
  final WsEventBus _eventBus;
  final ChatRepository _chatRepository;
  final UserRepository _userRepository;
  StreamSubscription<WsEvent>? _callSubscription;
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _listener;
  final Set<AudioPlayer> _soundPlayers = {};
  int _generation = 0;
  bool _backgroundEnabled = false;

  void setupListeners() {
    _callSubscription?.cancel();
    _callSubscription = _eventBus.subscribe(
      table: 'Call',
      action: ActionType.create,
      onData: (event) {
        if (event.isSelf || isClosed) return;
        final chatId = int.tryParse('${event.data['targetChatId']}');
        if (chatId == null) return;
        add(
          _IncomingCallSignal(
            IncomingCall(
              chatId: chatId,
              displayName: (event.data['displayName'] ?? 'Входящий звонок')
                  .toString(),
              username: event.data['username']?.toString(),
              pathImage: event.data['pathImage']?.toString(),
              isNsfw: event.data['isNsfw'] == true || event.data['isNsfw'] == 1,
              streamType: event.data['streamType']?.toString() ?? 'audio',
            ),
          ),
        );
      },
    );
  }

  void _onIncomingCall(_IncomingCallSignal event, Emitter<CallState> emit) {
    if (_userRepository.getCurrentUser()?.status == UserStatus.dnd ||
        state.incomingCall != null ||
        state.status == CallStatus.connecting ||
        state.status == CallStatus.connected) {
      return;
    }
    emit(state.copyWith(incomingCall: event.call));
  }

  Future<void> _announceOutgoingCall(int chatId, int generation) async {
    if (!_chatServerRepository.isConnected) return;
    Chat? chat = _chatRepository
        .getCached()
        .where((item) => item.id == chatId)
        .firstOrNull;
    final currentChat = _chatRepository.getCurrentChat();
    if (chat == null && currentChat?.id == chatId) chat = currentChat;
    if (chat == null) {
      final result = await _chatRepository.get();
      chat = result.fold(
        (_) => null,
        (chats) => chats.where((item) => item.id == chatId).firstOrNull,
      );
    }
    if (chat == null || chat.isSolo || chat.type == ChatType.channel) {
      return;
    }
    final user = _userRepository.getCurrentUser();
    if (user == null) return;
    if (isClosed ||
        generation != _generation ||
        state.status != CallStatus.connected ||
        state.chatId != chatId ||
        !_chatServerRepository.isConnected) {
      return;
    }
    final personal = chat.isPersonalChat || chat.type == ChatType.personal;
    _chatServerRepository.send({
      'nameAction': 'Call',
      'targetChatId': chatId,
      'pathImage': personal ? user.pathImage ?? '' : chat.pathImage ?? '',
      'username': user.username ?? '',
      'displayName': personal ? user.displayName ?? '' : chat.name,
      'isNsfw': personal ? user.isNsfw ?? false : false,
      'streamType': 'audio',
    });
  }

  Future<void> _onJoin(JoinCall event, Emitter<CallState> emit) async {
    if (state.status == CallStatus.connecting ||
        state.status == CallStatus.connected) {
      return;
    }
    final generation = ++_generation;
    emit(
      state.copyWith(
        status: CallStatus.connecting,
        chatId: event.chatId,
        entityKey: event.entityKey,
        title: event.title,
        error: null,
        clearIncomingCall: true,
      ),
    );
    final result = await _repository.getToken(
      chatId: event.chatId,
      entityKey: event.entityKey,
      lastIdMessage: event.lastIdMessage,
    );
    if (isClosed || generation != _generation) return;
    final token = result.fold((failure) => null, (value) => value);
    if (token == null) {
      emit(
        state.copyWith(
          status: CallStatus.failed,
          error: result.fold(
            (failure) => failure.message,
            (_) => 'Не удалось получить токен звонка',
          ),
        ),
      );
      return;
    }

    final room = lk.Room(
      roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true),
    );
    _room = room;
    _listener = room.createListener()
      ..on<lk.DataReceivedEvent>((event) {
        if (!isClosed) add(_CallDataReceived(event));
      })
      ..on<lk.RoomDisconnectedEvent>((event) {
        if (!isClosed) add(const _RoomDisconnected());
      })
      ..on<lk.ParticipantConnectedEvent>((event) {
        if (_room?.localParticipant != null) {
          unawaited(_publishDeviceState('headset', state.outputEnabled));
          unawaited(_publishDeviceState('microphone', state.microphoneEnabled));
        }
      })
      ..listen((event) {
        if (!isClosed &&
            event is! lk.DataReceivedEvent &&
            event is! lk.RoomDisconnectedEvent) {
          add(
            _RoomChanged(
              syncAudio:
                  event is lk.TrackSubscribedEvent ||
                  event is lk.TrackUnsubscribedEvent ||
                  event is lk.ParticipantConnectedEvent,
            ),
          );
        }
      });
    try {
      await room.connect(
        liveKitUrl,
        token.token,
        connectOptions: lk.ConnectOptions(
          rtcConfiguration: lk.RTCConfiguration(
            iceServers: token.iceServers
                .map(
                  (server) => lk.RTCIceServer(
                    urls: server.urls,
                    username: server.username,
                    credential: server.credential,
                  ),
                )
                .toList(),
          ),
        ),
      );
      if (isClosed || generation != _generation) {
        await room.disconnect();
        await room.dispose();
        return;
      }
      await lk.AudioManager.instance.setSpeakerOutputPreferred(true);
      // Видео никогда не публикуется автоматически. Микрофон включается после
      // разрешения ОС; отказ оставляет звонок доступным в режиме прослушивания.
      final micGranted = await Permission.microphone.request().isGranted;
      if (micGranted) await room.localParticipant?.setMicrophoneEnabled(true);
      await PipService.startCallService();
      await PipService.setCallActive(true);
      emit(
        state.copyWith(
          status: CallStatus.connected,
          room: room,
          microphoneEnabled: micGranted,
          cameraEnabled: false,
          screenShareEnabled: false,
          outputEnabled: true,
          error: null,
          revision: state.revision + 1,
        ),
      );
      await _publishDeviceState('headset', true);
      await _publishDeviceState('microphone', micGranted);
      if (event.announceCall && event.entityKey.entityType == EntityType.chat) {
        unawaited(
          _announceOutgoingCall(event.chatId, generation).catchError((
            Object error,
            StackTrace stackTrace,
          ) {
            debugPrint('Не удалось отправить сигнал звонка: $error');
          }),
        );
      }
    } catch (error) {
      await _releaseRoom();
      if (!isClosed && generation == _generation) {
        emit(
          state.copyWith(status: CallStatus.failed, error: error.toString()),
        );
      }
    }
  }

  Future<void> _onLeave(LeaveCall event, Emitter<CallState> emit) async {
    ++_generation;
    emit(state.copyWith(status: CallStatus.leaving));
    try {
      await _releaseRoom();
    } finally {
      emit(const CallState(status: CallStatus.left));
    }
  }

  Future<void> _onMicrophone(
    ToggleCallMicrophone event,
    Emitter<CallState> emit,
  ) async {
    final room = _room;
    if (room == null || state.status != CallStatus.connected) return;
    final enabled = !state.microphoneEnabled;
    if (enabled && !await Permission.microphone.request().isGranted) return;
    try {
      await room.localParticipant?.setMicrophoneEnabled(enabled);
      emit(
        state.copyWith(
          microphoneEnabled: enabled,
          revision: state.revision + 1,
        ),
      );
      await _publishDeviceState('microphone', enabled);
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> _onCamera(
    ToggleCallCamera event,
    Emitter<CallState> emit,
  ) async {
    final room = _room;
    if (room == null || state.status != CallStatus.connected) return;
    final enabled = !state.cameraEnabled;
    if (enabled && !await Permission.camera.request().isGranted) return;
    try {
      await room.localParticipant?.setCameraEnabled(
        enabled,
        cameraCaptureOptions: lk.CameraCaptureOptions(
          cameraPosition: state.cameraPosition,
        ),
      );
      emit(
        state.copyWith(cameraEnabled: enabled, revision: state.revision + 1),
      );
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> _onSwitchCamera(
    SwitchCallCamera event,
    Emitter<CallState> emit,
  ) async {
    final participant = _room?.localParticipant;
    if (participant == null || !state.cameraEnabled) return;
    final position = state.cameraPosition == lk.CameraPosition.front
        ? lk.CameraPosition.back
        : lk.CameraPosition.front;
    try {
      final track = participant
          .getTrackPublicationBySource(lk.TrackSource.camera)
          ?.track;
      if (track is lk.LocalVideoTrack) await track.setCameraPosition(position);
      emit(
        state.copyWith(cameraPosition: position, revision: state.revision + 1),
      );
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> _onOutput(
    ToggleCallOutput event,
    Emitter<CallState> emit,
  ) async {
    if (_room == null || state.status != CallStatus.connected) return;
    final enabled = !state.outputEnabled;
    emit(state.copyWith(outputEnabled: enabled));
    if (!enabled) {
      for (final player in _soundPlayers.toList()) {
        await player.stop();
      }
    }
    await _syncRemoteAudio(
      enabled: enabled,
      muted: state.locallyMutedParticipants,
    );
    await _publishDeviceState('headset', enabled);
  }

  Future<void> _onScreenShare(
    ToggleCallScreenShare event,
    Emitter<CallState> emit,
  ) async {
    final room = _room;
    if (room == null || state.status != CallStatus.connected) return;
    final enabled = !state.screenShareEnabled;
    try {
      if (enabled && Platform.isAndroid) {
        // Android 14 требует согласие MediaProjection до старта foreground service.
        if (!await rtc.Helper.requestCapturePermission(fullScreenOnly: true)) {
          return;
        }
        final ready = await FlutterBackground.initialize(
          androidConfig: const FlutterBackgroundAndroidConfig(
            notificationTitle: 'Disalive · демонстрация экрана',
            notificationText: 'Ваш экран показывается участникам звонка',
          ),
        );
        if (!ready || !await FlutterBackground.enableBackgroundExecution()) {
          throw StateError('Не удалось запустить демонстрацию экрана');
        }
        _backgroundEnabled = true;
      }
      await room.localParticipant?.setScreenShareEnabled(
        enabled,
        screenShareCaptureOptions: const lk.ScreenShareCaptureOptions(
          useiOSBroadcastExtension: false,
        ),
      );
      if (!enabled) await _disableBackground();
      emit(
        state.copyWith(
          screenShareEnabled: enabled,
          revision: state.revision + 1,
        ),
      );
    } catch (error) {
      if (enabled) await _disableBackground();
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> _onParticipantAudio(
    ToggleParticipantAudio event,
    Emitter<CallState> emit,
  ) async {
    final muted = {...state.locallyMutedParticipants};
    if (!muted.add(event.identity)) muted.remove(event.identity);
    emit(state.copyWith(locallyMutedParticipants: muted));
    await _syncRemoteAudio(enabled: state.outputEnabled, muted: muted);
  }

  Future<void> _onPlaySound(
    PlayCallSound event,
    Emitter<CallState> emit,
  ) async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    await participant.publishData(
      utf8.encode(
        jsonEncode({
          'type': 'play_sound',
          'soundName': event.path,
          'identity': participant.identity,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      ),
      reliable: true,
    );
    await _playSound(event.path);
  }

  Future<void> _onRoomChanged(
    _RoomChanged event,
    Emitter<CallState> emit,
  ) async {
    if (state.status != CallStatus.connected) return;
    final isSharing = _room?.localParticipant?.isScreenShareEnabled() ?? false;
    if (state.screenShareEnabled && !isSharing) await _disableBackground();
    if (event.syncAudio) {
      await _syncRemoteAudio(
        enabled: state.outputEnabled,
        muted: state.locallyMutedParticipants,
      );
    }
    emit(
      state.copyWith(
        screenShareEnabled: isSharing,
        microphoneEnabled:
            _room?.localParticipant?.isMicrophoneEnabled() ?? false,
        cameraEnabled: _room?.localParticipant?.isCameraEnabled() ?? false,
        revision: state.revision + 1,
      ),
    );
  }

  Future<void> _onDataReceived(
    _CallDataReceived event,
    Emitter<CallState> emit,
  ) async {
    try {
      final data = jsonDecode(utf8.decode(event.event.data));
      if (data is! Map) return;
      final identity =
          event.event.participant?.identity ?? data['identity']?.toString();
      if (data['type'] == 'device_state' &&
          data['device'] == 'headset' &&
          identity != null) {
        final value = data['state'];
        final enabled = value == 'on' || value == true;
        emit(
          state.copyWith(
            headsetStates: {...state.headsetStates, identity: enabled},
          ),
        );
      } else if (data['type'] == 'play_sound' &&
          identity != _room?.localParticipant?.identity) {
        final path = data['soundName'];
        if (path is String && path.isNotEmpty) await _playSound(path);
      }
    } catch (_) {
      // Пакеты data channel могут принадлежать другим возможностям клиента.
    }
  }

  Future<void> _onDisconnected(
    _RoomDisconnected event,
    Emitter<CallState> emit,
  ) async {
    if (state.status == CallStatus.leaving || state.status == CallStatus.left) {
      return;
    }
    await _releaseRoom();
    emit(const CallState(status: CallStatus.left));
  }

  Future<void> _publishDeviceState(String device, bool enabled) async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    try {
      await participant.publishData(
        utf8.encode(
          jsonEncode({
            'type': 'device_state',
            'device': device,
            'state': enabled ? 'on' : 'off',
            'identity': participant.identity,
          }),
        ),
        reliable: true,
      );
    } catch (_) {
      // Восстановление data channel не должно разрывать медиазвонок.
    }
  }

  Future<void> _syncRemoteAudio({
    required bool enabled,
    required Set<String> muted,
  }) async {
    for (final participant
        in _room?.remoteParticipants.values ?? <lk.RemoteParticipant>[]) {
      final shouldPlay = enabled && !muted.contains(participant.identity);
      for (final publication in participant.trackPublications.values) {
        final track = publication.track;
        if (track is lk.RemoteAudioTrack) {
          try {
            if (shouldPlay) {
              await track.enable();
            } else {
              await track.disable();
            }
          } catch (_) {
            // Трек мог быть удалён участником одновременно с переключением.
          }
        }
      }
    }
  }

  Future<void> _playSound(String path) async {
    if (!state.outputEnabled) return;
    final uri = Uri.tryParse(path);
    final url = uri?.hasScheme == true
        ? path
        : '${Domain.imageDomain}${path.replaceFirst(RegExp(r'^/+'), '')}';
    final player = AudioPlayer();
    _soundPlayers.add(player);
    player.onPlayerComplete.first.then((_) async {
      _soundPlayers.remove(player);
      await player.dispose();
    });
    try {
      await player.play(UrlSource(url), volume: 0.8);
    } catch (_) {
      _soundPlayers.remove(player);
      await player.dispose();
    }
  }

  Future<void> _disableBackground() async {
    if (_backgroundEnabled) {
      _backgroundEnabled = false;
      try {
        await FlutterBackground.disableBackgroundExecution();
      } catch (_) {}
    }
  }

  Future<void> _releaseRoom() async {
    final listener = _listener;
    _listener = null;
    try {
      await listener?.dispose();
    } catch (_) {}
    final room = _room;
    _room = null;
    if (room != null) {
      try {
        await room.disconnect();
      } catch (_) {}
      try {
        await room.dispose();
      } catch (_) {}
    }
    await _disableBackground();
    await PipService.setCallActive(false);
    await PipService.stopCallService();
    for (final player in _soundPlayers.toList()) {
      try {
        await player.dispose();
      } catch (_) {}
    }
    _soundPlayers.clear();
  }

  @override
  Future<void> close() async {
    ++_generation;
    await _callSubscription?.cancel();
    await _releaseRoom();
    await super.close();
  }
}

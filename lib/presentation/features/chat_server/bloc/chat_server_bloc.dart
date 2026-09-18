import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/ui/ws_connection_status.dart';
import 'package:disalive/domain/repositories/chat_server_repository.dart';
import 'package:disalive/domain/repositories/ws_repository.dart';
import 'package:flutter/cupertino.dart';

part 'chat_server_event.dart';

part 'chat_server_state.dart';

class ChatServerBloc extends Bloc<ChatServerEvent, ChatServerState>
    with WidgetsBindingObserver {
  final ChatServerRepository _chatServerRepository;

  bool _wasConnectedBeforeBackground = false;
  late final StreamSubscription<WsConnectionStatus> _statusSubscription;

  bool get isConnected => _chatServerRepository.isConnected;

  ChatServerBloc(this._chatServerRepository) : super(ChatServerInitial()) {
    on<ConnectToChatServer>(_onConnect);
    on<DisconnectFromChatServer>(_onDisconnect);
    on<SendChatServerMessage>(_onSend);
    on<SetConnection>(_setConnection);
    on<SetConnected>(_setConnected);
    on<SetDisconnection>(_setDisconnection);

    WidgetsBinding.instance.addObserver(this);
    _setupSubscription();
  }

  void _setupSubscription() {
    _statusSubscription = _chatServerRepository.connectionStatusStream.listen((
      status,
    ) {
      switch (status) {
        case WsConnectionStatus.connecting:
          add(SetConnection());
          break;
        case WsConnectionStatus.connected:
          add(SetConnected());
          break;
        case WsConnectionStatus.disconnected:
          if (state is! ChatServerDisconnected) {
            add(SetDisconnection());
          }
          break;
      }
    });
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _statusSubscription.cancel();
    _chatServerRepository.disconnect();
    return super.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Приложение ушло в фон. Запоминаем состояние и корректно закрываем сокет.
      _wasConnectedBeforeBackground = isConnected;
      _chatServerRepository.disconnect();
    } else if (state == AppLifecycleState.resumed) {
      if (_wasConnectedBeforeBackground) {
        add(ConnectToChatServer());
      }
    }
  }

  Future<void> _onConnect(
    ConnectToChatServer event,
    Emitter<ChatServerState> emit,
  ) async {
    if (_chatServerRepository.isConnected) {
      print("Already connected, skipping ConnectToChatServer.");
      return;
    }

    print("--------- START CONNECT TO CHAT SERVER ------------------");

    final connectResult = await _chatServerRepository.connect();

    if (connectResult.isLeft()) {
      final failure = connectResult.fold((l) => l, (r) => null);
      print('Initial connection failed, will retry: ${failure?.message}');
      return;
    }

    print('Chat server connected successfully');
  }

  void _onDisconnect(
    DisconnectFromChatServer event,
    Emitter<ChatServerState> emit,
  ) {
    _wasConnectedBeforeBackground = false;
    _chatServerRepository.disconnect();
    // Состояние Disconnected выставится через стрим автоматически
  }

  void _onSend(SendChatServerMessage event, Emitter<ChatServerState> emit) {
    _chatServerRepository.send(event.data);
  }

  FutureOr<void> _setConnection(
    SetConnection event,
    Emitter<ChatServerState> emit,
  ) {
    emit(ChatServerConnecting());
  }

  FutureOr<void> _setConnected(
    SetConnected event,
    Emitter<ChatServerState> emit,
  ) {
    emit(ChatServerConnected());
  }

  FutureOr<void> _setDisconnection(
    SetDisconnection event,
    Emitter<ChatServerState> emit,
  ) {
    emit(ChatServerDisconnected());
  }
}

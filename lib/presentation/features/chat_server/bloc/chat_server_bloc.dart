// lib/presentation/bloc/chat_server/chat_server_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:disalive/domain/repositories/chat_server_repository.dart';
import 'package:disalive/domain/repositories/ws_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

part 'chat_server_event.dart';

part 'chat_server_state.dart';

class ChatServerBloc extends Bloc<ChatServerEvent, ChatServerState>
    with WidgetsBindingObserver {
  final WsRepository _wsRepository;
  final ChatServerRepository _chatServerRepository;

  bool _wasConnectedBeforeBackground = false;

  ChatServerBloc(this._wsRepository, this._chatServerRepository)
    : super(ChatServerInitial()) {
    on<ConnectToChatServer>(_onConnect);
    on<DisconnectFromChatServer>(_onDisconnect);
    on<SendChatServerMessage>(_onSend);

    // Регистрируем наблюдатель за жизненным циклом приложения
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<void> close() {
    // Обязательно удаляем наблюдатель при уничтожении BLoC
    WidgetsBinding.instance.removeObserver(this);
    _chatServerRepository.disconnect();
    return super.close();
  }

  // 🎯 Магия отслеживания фона приложения
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Приложение ушло в фон. Запоминаем состояние и корректно закрываем сокет.
      _wasConnectedBeforeBackground =
          state == AppLifecycleState.resumed || isConnected;
      _chatServerRepository.disconnect();
      emit(ChatServerDisconnected());
    } else if (state == AppLifecycleState.resumed) {
      // Приложение вернулось на передний план. Если оно было подключено, переподключаем.
      if (_wasConnectedBeforeBackground) {
        add(ConnectToChatServer());
      }
    }
  }

  bool get isConnected => _chatServerRepository.isConnected;

  Future<void> _onConnect(
    ConnectToChatServer event,
    Emitter<ChatServerState> emit,
  ) async {
    print("--------- START CONNECT TO CHAT SERVER ------------------");
    emit(ChatServerConnecting());

    final tokenResult = await _wsRepository.getToken();

    if (tokenResult.isLeft()) {
      final failure = tokenResult.fold((l) => l, (r) => null);
      emit(ChatServerFailure(failure?.message ?? 'Unknown error'));
      return;
    }

    final token = tokenResult.fold((l) => '', (r) => r);
    final connectResult = await _chatServerRepository.connect(token);

    if (connectResult.isLeft()) {
      final failure = connectResult.fold((l) => l, (r) => null);
      // Не эмитим Failure здесь, так как Repository уже пытается переподключиться в фоне.
      // Но можно эмитить состояние "Попытка переподключения", если нужно для UI.
      print(
        'Initial connection failed, repository will retry: ${failure?.message}',
      );
      return;
    }

    print('Chat server connected successfully');
    emit(ChatServerConnected());
  }

  void _onDisconnect(
    DisconnectFromChatServer event,
    Emitter<ChatServerState> emit,
  ) {
    _wasConnectedBeforeBackground = false;
    _chatServerRepository.disconnect();
    emit(ChatServerDisconnected());
  }

  void _onSend(SendChatServerMessage event, Emitter<ChatServerState> emit) {
    _chatServerRepository.send(event.data);
  }
}

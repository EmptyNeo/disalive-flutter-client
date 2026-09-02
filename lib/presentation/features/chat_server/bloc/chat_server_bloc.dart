// lib/presentation/bloc/chat_server/chat_server_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:disalive/domain/repositories/chat_server_repository.dart';
import 'package:disalive/domain/repositories/ws_repository.dart';
import 'package:flutter/cupertino.dart';

part 'chat_server_event.dart';

part 'chat_server_state.dart';

class ChatServerBloc extends Bloc<ChatServerEvent, ChatServerState> {
  final WsRepository _wsRepository;
  final ChatServerRepository _chatServerRepository;

  ChatServerBloc(this._wsRepository, this._chatServerRepository)
    : super(ChatServerInitial()) {
    on<ConnectToChatServer>(_onConnect);
    on<DisconnectFromChatServer>(_onDisconnect);
    on<SendChatServerMessage>(_onSend);
  }

  Future<void> _onConnect(
    ConnectToChatServer event,
    Emitter<ChatServerState> emit,
  ) async {
    print("--------- START CONNECT TO CHAT SERVER ------------------");
    emit(ChatServerConnecting());

    final tokenResult = await _wsRepository.getToken();

    if (tokenResult.isLeft()) {
      final failure = tokenResult.fold((l) => l, (r) => null);
      print(failure?.message);
      emit(ChatServerFailure(failure?.message ?? 'Unknown error'));
      return;
    }

    final token = tokenResult.fold((l) => '', (r) => r);
    print(token);

    final connectResult = await _chatServerRepository.connect(token);

    if (connectResult.isLeft()) {
      final failure = connectResult.fold((l) => l, (r) => null);
      print(failure?.message);
      emit(ChatServerFailure(failure?.message ?? 'Unknown error'));
      return;
    }

    print('chat server connected');
    emit(ChatServerConnected());
  }

  void _onDisconnect(
    DisconnectFromChatServer event,
    Emitter<ChatServerState> emit,
  ) {
    _chatServerRepository.disconnect();
    emit(ChatServerDisconnected());
  }

  void _onSend(SendChatServerMessage event, Emitter<ChatServerState> emit) {
    _chatServerRepository.send(event.data);
  }
}

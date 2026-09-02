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
    emit(ChatServerConnecting());

    final tokenResult = await _wsRepository.getToken();

    tokenResult.fold(
      (failure) {
        emit(ChatServerFailure(failure.message));
      },
      (token) async {
        final connectResult = await _chatServerRepository.connect(token);

        connectResult.fold(
          (failure) {
            emit(ChatServerFailure(failure.message));
          },
          (_) {
            emit(ChatServerConnected());
          },
        );
      },
    );
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

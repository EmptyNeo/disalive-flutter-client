// lib/presentation/bloc/chat_server/chat_server_state.dart
part of 'chat_server_bloc.dart';

@immutable
abstract class ChatServerState {}

class ChatServerInitial extends ChatServerState {}

class ChatServerConnecting extends ChatServerState {}

class ChatServerConnected extends ChatServerState {}

class ChatServerDisconnected extends ChatServerState {}

class ChatServerFailure extends ChatServerState {
  final String error;

  ChatServerFailure(this.error);
}
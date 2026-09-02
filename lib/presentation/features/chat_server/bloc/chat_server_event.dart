// lib/presentation/bloc/chat_server/chat_server_event.dart
part of 'chat_server_bloc.dart';

@immutable
abstract class ChatServerEvent {}

class ConnectToChatServer extends ChatServerEvent {}

class DisconnectFromChatServer extends ChatServerEvent {}

class SendChatServerMessage extends ChatServerEvent {
  final Map<String, dynamic> data;

  SendChatServerMessage(this.data);
}

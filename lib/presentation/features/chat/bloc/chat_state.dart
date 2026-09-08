// lib/presentation/features/chat/bloc/chat_state.dart
part of 'chat_bloc.dart';

@immutable
abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Chat> chats;
  final int unreadCount;

  ChatLoaded(this.chats, this.unreadCount);
}

class ChatFailure extends ChatState {
  final String error;

  ChatFailure(this.error);
}

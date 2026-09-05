// lib/presentation/features/chat/bloc/chat_event.dart
part of 'chat_bloc.dart';

@immutable
abstract class ChatEvent {}

class GetChats extends ChatEvent {}

// В ChatEvent:
class AddMessageToChat extends ChatEvent {
  final Message message;
  final bool isSelf;

  AddMessageToChat({required this.message, required this.isSelf});
}

class AddChat extends ChatEvent {
  final Chat chat;

  AddChat(this.chat);
}

class UpdateChat extends ChatEvent {
  final Chat chat;

  UpdateChat(this.chat);
}

class DeleteChat extends ChatEvent {
  final int chatId;

  DeleteChat(this.chatId);
}

// В chat_event.dart добавьте:
class UpdateUserInChat extends ChatEvent {
  final UserModel user;

  UpdateUserInChat(this.user);
}

class SearchChats extends ChatEvent {
  final String query;

  SearchChats(this.query);
}

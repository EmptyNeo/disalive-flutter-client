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

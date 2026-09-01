// lib/presentation/features/chat/bloc/chat_event.dart
part of 'chat_bloc.dart';

@immutable
abstract class ChatEvent {}

class GetChats extends ChatEvent {}

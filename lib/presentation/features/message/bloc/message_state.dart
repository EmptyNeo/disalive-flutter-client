// lib/presentation/features/message/bloc/message_state.dart
part of 'message_bloc.dart';

@immutable
abstract class MessageState {}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class MessageLoaded extends MessageState {
  final List<Message> messages;
  final List<HistoryAction> actions;
  final bool isLoadingMore;

  MessageLoaded({
    required this.messages,
    required this.actions,
    this.isLoadingMore = false,
  });
}

class MessageFailure extends MessageState {
  final String error;

  MessageFailure(this.error);
}

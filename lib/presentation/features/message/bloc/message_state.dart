// lib/presentation/features/message/bloc/message_state.dart
part of 'message_bloc.dart';

@immutable
abstract class MessageState {
  int? get chatId;
}

class MessageInitial extends MessageState {
  @override
  int? get chatId => null;
}

class MessageLoading extends MessageState {
  MessageLoading(this.chatId);

  @override
  final int chatId;
}

class MessageLoaded extends MessageState {
  @override
  final int chatId;
  final List<Message> messages;
  final List<HistoryAction> actions;
  final bool isLoadingMore;
  final bool isLoadingNewer;
  final bool hasMoreMessages;
  final bool hasNewerMessages;

  MessageLoaded({
    required this.chatId,
    required this.messages,
    required this.actions,
    this.isLoadingMore = false,
    this.isLoadingNewer = false,
    this.hasMoreMessages = true,
    this.hasNewerMessages = true,
  });

  MessageLoaded copyWith({
    List<Message>? messages,
    List<HistoryAction>? actions,
    bool? isLoadingMore,
    bool? isLoadingNewer,
    bool? hasMoreMessages,
    bool? hasNewerMessages,
  }) {
    return MessageLoaded(
      chatId: chatId,
      messages: messages ?? this.messages,
      actions: actions ?? this.actions,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoadingNewer: isLoadingNewer ?? this.isLoadingNewer,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      hasNewerMessages: hasNewerMessages ?? this.hasNewerMessages,
    );
  }
}

class MessageFailure extends MessageState {
  @override
  final int chatId;
  final Failure error;

  MessageFailure(this.error, this.chatId);
}

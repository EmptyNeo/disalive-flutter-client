import 'package:equatable/equatable.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/history_action.dart';

class MessagesResponse extends Equatable {
  final List<Message> messages;
  final List<HistoryAction> actions;

  const MessagesResponse({
    required this.messages,
    required this.actions,
  });

  factory MessagesResponse.fromMap(Map<String, dynamic> map) {
    return MessagesResponse(
      messages: map['messages'] != null
          ? (map['messages'] as List)
          .map((e) => Message.fromMap(e as Map<String, dynamic>))
          .toList()
          : <Message>[],
      actions: map['actions'] != null
          ? (map['actions'] as List)
          .map((e) => HistoryAction.fromMap(e as Map<String, dynamic>))
          .toList()
          : <HistoryAction>[],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messages': messages.map((e) => e.toMap()).toList(),
      'actions': actions.map((e) => e.toMap()).toList(),
    };
  }

  MessagesResponse copyWith({
    List<Message>? messages,
    List<HistoryAction>? actions,
  }) {
    return MessagesResponse(
      messages: messages ?? this.messages,
      actions: actions ?? this.actions,
    );
  }

  @override
  List<Object?> get props => [messages, actions];
}
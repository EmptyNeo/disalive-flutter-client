// lib/domain/models/reaction_message.dart
import 'package:equatable/equatable.dart';

class ReactionMessage extends Equatable {
  final int? id;
  final int? messageId;
  final int? userId;
  final String? nameReaction;
  final int? amount;
  final bool? hasUserReaction;

  const ReactionMessage({
    this.id,
    this.messageId,
    this.userId,
    this.nameReaction,
    this.amount,
    this.hasUserReaction,
  });

  factory ReactionMessage.fromMap(Map<String, dynamic> map) {
    return ReactionMessage(
      id: map['id'],
      messageId: map['messageId'],
      userId: map['userId'],
      nameReaction: map['nameReaction'],
      amount: map['amount'],
      hasUserReaction: map['hasUserReaction'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (messageId != null) 'messageId': messageId,
      if (userId != null) 'userId': userId,
      if (nameReaction != null) 'nameReaction': nameReaction,
      if (amount != null) 'amount': amount,
      if (hasUserReaction != null) 'hasUserReaction': hasUserReaction,
    };
  }

  ReactionMessage copyWith({
    int? id,
    int? messageId,
    int? userId,
    String? nameReaction,
    int? amount,
    bool? hasUserReaction,
  }) {
    return ReactionMessage(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      nameReaction: nameReaction ?? this.nameReaction,
      amount: amount ?? this.amount,
      hasUserReaction: hasUserReaction ?? this.hasUserReaction,
    );
  }

  bool get hasReaction => hasUserReaction ?? false;

  @override
  List<Object?> get props => [
    id,
    messageId,
    userId,
    nameReaction,
    amount,
    hasUserReaction,
  ];
}
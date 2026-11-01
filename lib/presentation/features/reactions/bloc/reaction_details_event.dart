part of 'reaction_details_bloc.dart';

abstract class ReactionDetailsEvent extends Equatable {
  const ReactionDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadReactionSummary extends ReactionDetailsEvent {
  const LoadReactionSummary({
    required this.messageId,
    required this.entityId,
    required this.entityType,
  });

  final int messageId;
  final int entityId;
  final EntityType entityType;

  @override
  List<Object?> get props => [messageId, entityId, entityType];
}

class LoadMoreReactionSummary extends ReactionDetailsEvent {
  const LoadMoreReactionSummary();
}

class LoadReactionUsers extends ReactionDetailsEvent {
  const LoadReactionUsers({
    required this.messageId,
    required this.entityId,
    required this.entityType,
    required this.nameReaction,
  });

  final int messageId;
  final int entityId;
  final EntityType entityType;
  final String nameReaction;

  @override
  List<Object?> get props => [messageId, entityId, entityType, nameReaction];
}

class LoadMoreReactionUsers extends ReactionDetailsEvent {
  const LoadMoreReactionUsers();
}

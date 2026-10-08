part of 'preferred_reactions_bloc.dart';

abstract class PreferredReactionsEvent extends Equatable {
  const PreferredReactionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPreferredReactions extends PreferredReactionsEvent {
  const LoadPreferredReactions();
}

class UpsertPreferredReaction extends PreferredReactionsEvent {
  final String nameReaction;

  const UpsertPreferredReaction({required this.nameReaction});

  @override
  List<Object?> get props => [nameReaction];
}
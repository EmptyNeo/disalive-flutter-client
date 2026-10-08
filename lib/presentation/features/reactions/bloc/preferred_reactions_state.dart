part of 'preferred_reactions_bloc.dart';

abstract class PreferredReactionsState extends Equatable {
  const PreferredReactionsState();

  @override
  List<Object?> get props => [];
}

class PreferredReactionsInitial extends PreferredReactionsState {}

class PreferredReactionsLoaded extends PreferredReactionsState {
  final List<PreferredReaction> reactions;

  const PreferredReactionsLoaded(this.reactions);

  @override
  List<Object?> get props => [reactions];
}

class PreferredReactionsFailure extends PreferredReactionsState {
  final Failure failure;

  const PreferredReactionsFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
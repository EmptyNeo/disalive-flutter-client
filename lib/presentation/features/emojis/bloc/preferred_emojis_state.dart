part of 'preferred_emojis_bloc.dart';

abstract class PreferredEmojisState extends Equatable {
  const PreferredEmojisState();

  @override
  List<Object?> get props => [];
}

class PreferredEmojisInitial extends PreferredEmojisState {}

class PreferredEmojisLoaded extends PreferredEmojisState {
  final List<PreferredEmoji> emojis;

  const PreferredEmojisLoaded(this.emojis);

  @override
  List<Object?> get props => [emojis];
}

class PreferredEmojisFailure extends PreferredEmojisState {
  final Failure failure;

  const PreferredEmojisFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}

part of 'preferred_emojis_bloc.dart';

abstract class PreferredEmojisEvent extends Equatable {
  const PreferredEmojisEvent();

  @override
  List<Object?> get props => [];
}

class LoadPreferredEmojis extends PreferredEmojisEvent {
  const LoadPreferredEmojis();
}

class UpsertPreferredEmoji extends PreferredEmojisEvent {
  final String emoji;

  const UpsertPreferredEmoji({required this.emoji});

  @override
  List<Object?> get props => [emoji];
}

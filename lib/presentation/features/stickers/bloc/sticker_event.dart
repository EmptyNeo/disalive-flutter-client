part of 'sticker_bloc.dart';

abstract class StickerEvent extends Equatable {
  const StickerEvent();

  @override
  List<Object?> get props => [];
}

class LoadStickerPacks extends StickerEvent {
  final int skip;
  final int take;

  const LoadStickerPacks({required this.skip, required this.take});

  @override
  List<Object?> get props => [skip, take];
}

class LoadStickerPackDetails extends StickerEvent {
  final int packId;
  final int skip;
  final int take;

  const LoadStickerPackDetails({
    required this.packId,
    required this.skip,
    required this.take,
  });

  @override
  List<Object?> get props => [packId, skip, take];
}

class ClearStickers extends StickerEvent {
  const ClearStickers();
}
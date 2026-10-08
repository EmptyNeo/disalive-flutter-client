part of 'stickers_pack_bloc.dart';

abstract class StickerPackEvent extends Equatable {
  const StickerPackEvent();

  @override
  List<Object?> get props => [];
}

class LoadStickerPacks extends StickerPackEvent {
  final int skip;
  final int take;

  const LoadStickerPacks({required this.skip, required this.take});

  @override
  List<Object?> get props => [skip, take];
}

class LoadStickerPackDetails extends StickerPackEvent {
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

class CreateStickerPack extends StickerPackEvent {
  final String packName;

  const CreateStickerPack(this.packName);

  @override
  List<Object?> get props => [packName];
}

class UpdateStickerPack extends StickerPackEvent {
  final int packId;
  final String packName;

  const UpdateStickerPack(this.packId, this.packName);

  @override
  List<Object?> get props => [packId, packName];
}

class AddStickerPack extends StickerPackEvent {
  final int packId;

  const AddStickerPack(this.packId);

  @override
  List<Object?> get props => [packId];
}

class RemoveStickerPack extends StickerPackEvent {
  final int packId;

  const RemoveStickerPack(this.packId);

  @override
  List<Object?> get props => [packId];
}

class ClearStickers extends StickerPackEvent {
  const ClearStickers();
}

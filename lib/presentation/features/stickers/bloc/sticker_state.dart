part of 'sticker_bloc.dart';

abstract class StickerState extends Equatable {
  const StickerState();

  @override
  List<Object?> get props => [];
}

class StickerInitial extends StickerState {}

class StickerLoading extends StickerState {}

class StickerLoaded extends StickerState {
  final List<StickerPack> packs;
  final int skip;
  final int take;
  final bool hasReachedMax;

  final StickerPack? activePack;
  final bool isLoadingActivePack;

  const StickerLoaded({
    required this.packs,
    required this.skip,
    required this.take,
    required this.hasReachedMax,
    this.activePack,
    this.isLoadingActivePack = false,
  });

  StickerLoaded copyWith({
    List<StickerPack>? packs,
    int? skip,
    int? take,
    bool? hasReachedMax,
    StickerPack? activePack,
    bool? isLoadingActivePack,
  }) {
    return StickerLoaded(
      packs: packs ?? this.packs,
      skip: skip ?? this.skip,
      take: take ?? this.take,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      activePack: activePack ?? this.activePack,
      isLoadingActivePack: isLoadingActivePack ?? this.isLoadingActivePack,
    );
  }

  @override
  List<Object?> get props => [
    packs,
    skip,
    take,
    hasReachedMax,
    activePack,
    isLoadingActivePack,
  ];
}

class StickerError extends StickerState {
  final Failure failure;

  const StickerError(this.failure);

  @override
  List<Object?> get props => [failure];
}

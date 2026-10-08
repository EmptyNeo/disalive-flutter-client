part of 'stickers_pack_bloc.dart';

abstract class StickersPackState extends Equatable {
  const StickersPackState();

  @override
  List<Object?> get props => [];
}

class StickersPackInitial extends StickersPackState {}

class StickersPackLoading extends StickersPackState {}

class StickersPackLoaded extends StickersPackState {
  final List<StickerPack> packs;
  final int skip;
  final int take;
  final bool hasReachedMax;

  final StickerPack? activePack;
  final bool isLoadingActivePack;

  const StickersPackLoaded({
    required this.packs,
    required this.skip,
    required this.take,
    required this.hasReachedMax,
    this.activePack,
    this.isLoadingActivePack = false,
  });

  StickersPackLoaded copyWith({
    List<StickerPack>? packs,
    int? skip,
    int? take,
    bool? hasReachedMax,
    StickerPack? activePack,
    bool? isLoadingActivePack,
  }) {
    return StickersPackLoaded(
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

class StickersPackError extends StickersPackState {
  final Failure failure;

  const StickersPackError(this.failure);

  @override
  List<Object?> get props => [failure];
}

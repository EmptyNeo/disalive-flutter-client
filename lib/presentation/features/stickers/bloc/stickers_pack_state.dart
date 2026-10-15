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

  /// packId -> сколько стикеров сейчас загружается
  final Map<int, int> uploadingByPack;

  /// Ошибка последнего действия со стикером (не затирает список паков)
  final Failure? actionFailure;

  const StickersPackLoaded({
    required this.packs,
    required this.skip,
    required this.take,
    required this.hasReachedMax,
    this.activePack,
    this.isLoadingActivePack = false,
    this.uploadingByPack = const {},
    this.actionFailure,
  });

  int uploadingIn(int packId) => uploadingByPack[packId] ?? 0;

  StickersPackLoaded bumpUploading(int packId, int delta) {
    final map = Map<int, int>.from(uploadingByPack);
    final next = (map[packId] ?? 0) + delta;
    if (next <= 0) {
      map.remove(packId);
    } else {
      map[packId] = next;
    }
    return copyWith(uploadingByPack: map);
  }

  StickersPackLoaded copyWith({
    List<StickerPack>? packs,
    int? skip,
    int? take,
    bool? hasReachedMax,
    StickerPack? activePack,
    bool? isLoadingActivePack,
    Map<int, int>? uploadingByPack,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return StickersPackLoaded(
      packs: packs ?? this.packs,
      skip: skip ?? this.skip,
      take: take ?? this.take,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      activePack: activePack ?? this.activePack,
      isLoadingActivePack: isLoadingActivePack ?? this.isLoadingActivePack,
      uploadingByPack: uploadingByPack ?? this.uploadingByPack,
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
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
    uploadingByPack,
    actionFailure,
  ];
}

class StickersPackError extends StickersPackState {
  final Failure failure;

  const StickersPackError(this.failure);

  @override
  List<Object?> get props => [failure];
}

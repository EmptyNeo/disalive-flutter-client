part of 'media_filters_bloc.dart';

class MediaFiltersState extends Equatable {
  const MediaFiltersState({
    this.chatId,
    this.category,
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final int? chatId;
  final MediaFilterCategory? category;
  final List<MediaFilterItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  MediaFiltersState copyWith({
    List<MediaFilterItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) => MediaFiltersState(
    chatId: chatId,
    category: category,
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : error ?? this.error,
  );

  @override
  List<Object?> get props => [
    chatId,
    category,
    items,
    isLoading,
    isLoadingMore,
    hasMore,
    error,
  ];
}

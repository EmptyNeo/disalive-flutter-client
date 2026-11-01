part of 'reaction_details_bloc.dart';

abstract class ReactionDetailsState extends Equatable {
  const ReactionDetailsState();

  @override
  List<Object?> get props => [];
}

class ReactionDetailsInitial extends ReactionDetailsState {}

class ReactionDetailsLoading extends ReactionDetailsState {
  const ReactionDetailsLoading({required this.isUsers});

  final bool isUsers;

  @override
  List<Object?> get props => [isUsers];
}

class ReactionDetailsFailure extends ReactionDetailsState {
  const ReactionDetailsFailure({required this.failure, required this.isUsers});

  final Failure failure;
  final bool isUsers;

  @override
  List<Object?> get props => [failure, isUsers];
}

class ReactionSummaryLoaded extends ReactionDetailsState {
  const ReactionSummaryLoaded({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    this.isLoadingMore = false,
    this.paginationFailure,
  });

  final List<ReactionSummary> items;
  final int? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final Failure? paginationFailure;

  ReactionSummaryLoaded copyWith({
    List<ReactionSummary>? items,
    int? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? paginationFailure,
    bool clearPaginationFailure = false,
  }) => ReactionSummaryLoaded(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    paginationFailure: clearPaginationFailure
        ? null
        : (paginationFailure ?? this.paginationFailure),
  );

  @override
  List<Object?> get props => [
    items,
    nextCursor,
    hasMore,
    isLoadingMore,
    paginationFailure,
  ];
}

class ReactionUsersLoaded extends ReactionDetailsState {
  const ReactionUsersLoaded({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    this.isLoadingMore = false,
    this.paginationFailure,
  });

  final List<UserModel> items;
  final int? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final Failure? paginationFailure;

  ReactionUsersLoaded copyWith({
    List<UserModel>? items,
    int? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? paginationFailure,
    bool clearPaginationFailure = false,
  }) => ReactionUsersLoaded(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    paginationFailure: clearPaginationFailure
        ? null
        : (paginationFailure ?? this.paginationFailure),
  );

  @override
  List<Object?> get props => [
    items,
    nextCursor,
    hasMore,
    isLoadingMore,
    paginationFailure,
  ];
}

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/reaction_summary.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:equatable/equatable.dart';

part 'reaction_details_event.dart';
part 'reaction_details_state.dart';

class ReactionDetailsBloc
    extends Bloc<ReactionDetailsEvent, ReactionDetailsState> {
  ReactionDetailsBloc(this._repository) : super(ReactionDetailsInitial()) {
    on<LoadReactionSummary>(_onLoadSummary);
    on<LoadMoreReactionSummary>(_onLoadMoreSummary);
    on<LoadReactionUsers>(_onLoadUsers);
    on<LoadMoreReactionUsers>(_onLoadMoreUsers);
  }

  final ReactionsRepository _repository;
  int? _messageId;
  int? _entityId;
  EntityType? _entityType;
  String? _nameReaction;
  bool _loadingSummary = false;
  bool _loadingUsers = false;

  Future<void> _onLoadSummary(
    LoadReactionSummary event,
    Emitter<ReactionDetailsState> emit,
  ) async {
    if (_loadingSummary) return;
    _messageId = event.messageId;
    _entityId = event.entityId;
    _entityType = event.entityType;
    _nameReaction = null;
    _loadingSummary = true;
    emit(const ReactionDetailsLoading(isUsers: false));
    final result = await _repository.getByMessage(
      messageId: event.messageId,
      entityId: event.entityId,
      entityType: event.entityType,
    );
    _loadingSummary = false;
    result.fold(
      (failure) =>
          emit(ReactionDetailsFailure(failure: failure, isUsers: false)),
      (page) => emit(
        ReactionSummaryLoaded(
          items: page.items,
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> _onLoadMoreSummary(
    LoadMoreReactionSummary event,
    Emitter<ReactionDetailsState> emit,
  ) async {
    final current = state;
    final messageId = _messageId;
    final entityId = _entityId;
    final entityType = _entityType;
    if (_loadingSummary ||
        current is! ReactionSummaryLoaded ||
        !current.hasMore ||
        current.nextCursor == null ||
        messageId == null ||
        entityId == null ||
        entityType == null) {
      return;
    }
    _loadingSummary = true;
    emit(current.copyWith(isLoadingMore: true, clearPaginationFailure: true));
    final result = await _repository.getByMessage(
      messageId: messageId,
      entityId: entityId,
      entityType: entityType,
      cursor: current.nextCursor!,
    );
    _loadingSummary = false;
    result.fold(
      (failure) {
        final latest = state;
        if (latest is ReactionSummaryLoaded) {
          emit(
            latest.copyWith(isLoadingMore: false, paginationFailure: failure),
          );
        }
      },
      (page) {
        final latest = state;
        if (latest is ReactionSummaryLoaded) {
          emit(
            latest.copyWith(
              items: [...latest.items, ...page.items],
              nextCursor: page.nextCursor,
              hasMore: page.hasMore,
              isLoadingMore: false,
              clearPaginationFailure: true,
            ),
          );
        }
      },
    );
  }

  Future<void> _onLoadUsers(
    LoadReactionUsers event,
    Emitter<ReactionDetailsState> emit,
  ) async {
    if (_loadingUsers) return;
    _messageId = event.messageId;
    _entityId = event.entityId;
    _entityType = event.entityType;
    _nameReaction = event.nameReaction;
    _loadingUsers = true;
    emit(const ReactionDetailsLoading(isUsers: true));
    final result = await _repository.getUsersByMessage(
      messageId: event.messageId,
      entityId: event.entityId,
      entityType: event.entityType,
      nameReaction: event.nameReaction,
    );
    _loadingUsers = false;
    result.fold(
      (failure) =>
          emit(ReactionDetailsFailure(failure: failure, isUsers: true)),
      (page) => emit(
        ReactionUsersLoaded(
          items: page.items,
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> _onLoadMoreUsers(
    LoadMoreReactionUsers event,
    Emitter<ReactionDetailsState> emit,
  ) async {
    final current = state;
    final messageId = _messageId;
    final entityId = _entityId;
    final entityType = _entityType;
    final nameReaction = _nameReaction;
    if (_loadingUsers ||
        current is! ReactionUsersLoaded ||
        !current.hasMore ||
        current.nextCursor == null ||
        messageId == null ||
        entityId == null ||
        entityType == null ||
        nameReaction == null) {
      return;
    }
    _loadingUsers = true;
    emit(current.copyWith(isLoadingMore: true, clearPaginationFailure: true));
    final result = await _repository.getUsersByMessage(
      messageId: messageId,
      entityId: entityId,
      entityType: entityType,
      nameReaction: nameReaction,
      cursor: current.nextCursor!,
    );
    _loadingUsers = false;
    result.fold(
      (failure) {
        final latest = state;
        if (latest is ReactionUsersLoaded) {
          emit(
            latest.copyWith(isLoadingMore: false, paginationFailure: failure),
          );
        }
      },
      (page) {
        final latest = state;
        if (latest is ReactionUsersLoaded) {
          emit(
            latest.copyWith(
              items: [...latest.items, ...page.items],
              nextCursor: page.nextCursor,
              hasMore: page.hasMore,
              isLoadingMore: false,
              clearPaginationFailure: true,
            ),
          );
        }
      },
    );
  }
}

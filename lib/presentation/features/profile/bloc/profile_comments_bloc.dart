import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/profile_comment.dart';
import 'package:disalive/domain/models/profile_comment_like_result.dart';
import 'package:disalive/domain/repositories/profile_comment_likes_repository.dart';
import 'package:disalive/domain/repositories/profile_comments_repository.dart';

sealed class ProfileCommentsEvent {
  const ProfileCommentsEvent();
}

class ProfileCommentsLoad extends ProfileCommentsEvent {
  final int profileUserId;
  const ProfileCommentsLoad(this.profileUserId);
}

class ProfileCommentsLoadMore extends ProfileCommentsEvent {
  const ProfileCommentsLoadMore();
}

class ProfileCommentCreate extends ProfileCommentsEvent {
  final String content;
  final int? parentCommentId;
  const ProfileCommentCreate(this.content, {this.parentCommentId});
}

class ProfileCommentUpdate extends ProfileCommentsEvent {
  final int commentId;
  final String content;
  const ProfileCommentUpdate(this.commentId, this.content);
}

class ProfileCommentDelete extends ProfileCommentsEvent {
  final int commentId;
  const ProfileCommentDelete(this.commentId);
}

class ProfileCommentLikeToggle extends ProfileCommentsEvent {
  final int commentId;
  const ProfileCommentLikeToggle(this.commentId);
}

class ProfileCommentsState {
  final int? profileUserId;
  final List<ProfileComment> comments;
  final int offset;
  final bool hasMore;
  final bool loading;
  final bool loadingMore;
  final bool saving;
  final Set<int> likingCommentIds;
  final Failure? error;
  final Failure? actionError;
  final int revision;

  const ProfileCommentsState({
    this.profileUserId,
    this.comments = const [],
    this.offset = 0,
    this.hasMore = false,
    this.loading = false,
    this.loadingMore = false,
    this.saving = false,
    this.likingCommentIds = const {},
    this.error,
    this.actionError,
    this.revision = 0,
  });

  ProfileCommentsState copyWith({
    List<ProfileComment>? comments,
    int? offset,
    bool? hasMore,
    bool? loading,
    bool? loadingMore,
    bool? saving,
    Set<int>? likingCommentIds,
    Failure? error,
    Failure? actionError,
    bool clearErrors = false,
    int? revision,
  }) => ProfileCommentsState(
    profileUserId: profileUserId,
    comments: comments ?? this.comments,
    offset: offset ?? this.offset,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    saving: saving ?? this.saving,
    likingCommentIds: likingCommentIds ?? this.likingCommentIds,
    error: clearErrors ? null : error ?? this.error,
    actionError: clearErrors ? null : actionError ?? this.actionError,
    revision: revision ?? this.revision,
  );
}

class ProfileCommentsBloc
    extends Bloc<ProfileCommentsEvent, ProfileCommentsState> {
  ProfileCommentsBloc(this._repository, this._likesRepository)
    : super(const ProfileCommentsState()) {
    on<ProfileCommentsLoad>(_onLoad);
    on<ProfileCommentsLoadMore>(_onLoadMore);
    on<ProfileCommentCreate>(_onCreate);
    on<ProfileCommentUpdate>(_onUpdate);
    on<ProfileCommentDelete>(_onDelete);
    on<ProfileCommentLikeToggle>(_onLikeToggle);
  }

  final ProfileCommentsRepository _repository;
  final ProfileCommentLikesRepository _likesRepository;
  static const _pageSize = 20;

  Future<void> _onLoad(
    ProfileCommentsLoad event,
    Emitter<ProfileCommentsState> emit,
  ) async {
    emit(
      ProfileCommentsState(profileUserId: event.profileUserId, loading: true),
    );
    final result = await _repository.getComments(event.profileUserId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(loading: false, error: failure)),
      (page) => emit(
        state.copyWith(
          comments: page.comments,
          offset: page.offset + page.limit,
          hasMore: page.hasMore,
          loading: false,
          clearErrors: true,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    ProfileCommentsLoadMore event,
    Emitter<ProfileCommentsState> emit,
  ) async {
    final userId = state.profileUserId;
    if (userId == null ||
        !state.hasMore ||
        state.loadingMore ||
        state.loading ||
        state.saving) {
      return;
    }
    emit(state.copyWith(loadingMore: true, clearErrors: true));
    final result = await _repository.getComments(userId, offset: state.offset);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(loadingMore: false, actionError: failure)),
      (page) => emit(
        state.copyWith(
          comments: [...state.comments, ...page.comments],
          offset: page.offset + page.limit,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      ),
    );
  }

  Future<void> _onCreate(
    ProfileCommentCreate event,
    Emitter<ProfileCommentsState> emit,
  ) async {
    final userId = state.profileUserId;
    if (userId == null || state.saving) return;
    final content = event.content.trim();
    if (!_valid(content, emit)) return;
    emit(state.copyWith(saving: true, clearErrors: true));
    final result = await _repository.createComment(
      userId,
      content,
      parentCommentId: event.parentCommentId,
    );
    await _finishMutation(
      result.isLeft(),
      result.fold((failure) => failure, (_) => null),
      emit,
    );
  }

  Future<void> _onUpdate(
    ProfileCommentUpdate event,
    Emitter<ProfileCommentsState> emit,
  ) async {
    if (state.saving) return;
    final content = event.content.trim();
    if (!_valid(content, emit)) return;
    emit(state.copyWith(saving: true, clearErrors: true));
    final result = await _repository.updateComment(event.commentId, content);
    await _finishMutation(
      result.isLeft(),
      result.fold((failure) => failure, (_) => null),
      emit,
    );
  }

  Future<void> _onDelete(
    ProfileCommentDelete event,
    Emitter<ProfileCommentsState> emit,
  ) async {
    if (state.saving) return;
    emit(state.copyWith(saving: true, clearErrors: true));
    final result = await _repository.deleteComment(event.commentId);
    await _finishMutation(
      result.isLeft(),
      result.fold((failure) => failure, (_) => null),
      emit,
    );
  }

  Future<void> _onLikeToggle(
    ProfileCommentLikeToggle event,
    Emitter<ProfileCommentsState> emit,
  ) async {
    if (state.likingCommentIds.contains(event.commentId)) return;
    final comment = _findComment(state.comments, event.commentId);
    if (comment == null || comment.isDeleted) return;
    emit(
      state.copyWith(
        likingCommentIds: {...state.likingCommentIds, event.commentId},
        clearErrors: true,
      ),
    );
    final result = comment.isLiked
        ? await _likesRepository.unlike(event.commentId)
        : await _likesRepository.like(event.commentId);
    if (isClosed) return;
    final pending = {...state.likingCommentIds}..remove(event.commentId);
    result.fold(
      (failure) =>
          emit(state.copyWith(likingCommentIds: pending, actionError: failure)),
      (updated) => emit(
        state.copyWith(
          likingCommentIds: pending,
          comments: _replaceLike(state.comments, updated),
          clearErrors: true,
        ),
      ),
    );
  }

  ProfileComment? _findComment(List<ProfileComment> comments, int id) {
    for (final comment in comments) {
      if (comment.id == id) return comment;
      final nested = _findComment(comment.replies, id);
      if (nested != null) return nested;
    }
    return null;
  }

  List<ProfileComment> _replaceLike(
    List<ProfileComment> comments,
    ProfileCommentLikeResult updated,
  ) => [
    for (final comment in comments)
      if (comment.id == updated.commentId)
        comment.withLikes(
          likesCount: updated.likesCount,
          isLiked: updated.isLiked,
        )
      else if (comment.replies.isNotEmpty)
        comment.withReplies(_replaceLike(comment.replies, updated))
      else
        comment,
  ];

  bool _valid(String content, Emitter<ProfileCommentsState> emit) {
    if (content.isNotEmpty && utf8.encode(content).length <= 1000) return true;
    emit(
      state.copyWith(
        actionError: const ServerFailure('Введите комментарий до 1000 байт'),
      ),
    );
    return false;
  }

  Future<void> _finishMutation(
    bool failed,
    Failure? failure,
    Emitter<ProfileCommentsState> emit,
  ) async {
    if (isClosed) return;
    if (failed) {
      emit(state.copyWith(saving: false, actionError: failure));
      return;
    }
    final userId = state.profileUserId;
    if (userId == null) return;
    // The server prunes deleted branches and returns nested replies. Reloading
    // keeps those rules authoritative after every write.
    final limit = state.offset > _pageSize ? state.offset : _pageSize;
    final result = await _repository.getComments(userId, limit: limit);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(saving: false, actionError: failure)),
      (page) => emit(
        state.copyWith(
          comments: page.comments,
          offset: page.offset + page.limit,
          hasMore: page.hasMore,
          saving: false,
          clearErrors: true,
          revision: state.revision + 1,
        ),
      ),
    );
  }
}

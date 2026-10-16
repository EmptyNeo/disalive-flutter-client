import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/media_filter_category.dart';
import 'package:disalive/domain/models/media_filter_item.dart';
import 'package:disalive/domain/repositories/media_filter_repository.dart';
import 'package:equatable/equatable.dart';

part 'media_filters_event.dart';
part 'media_filters_state.dart';

class MediaFiltersBloc extends Bloc<MediaFiltersEvent, MediaFiltersState> {
  MediaFiltersBloc(this._repository) : super(const MediaFiltersState()) {
    on<LoadMediaFilter>(_onLoad);
    on<LoadMoreMediaFilter>(_onLoadMore);
  }

  final MediaFilterRepository _repository;
  static const int pageSize = 25;
  int _generation = 0;

  Future<void> _onLoad(
    LoadMediaFilter event,
    Emitter<MediaFiltersState> emit,
  ) async {
    final generation = ++_generation;
    emit(
      MediaFiltersState(
        chatId: event.chatId,
        category: event.category,
        isLoading: true,
      ),
    );
    final result = await _fetch(event.chatId, event.category, 0);
    if (generation != _generation) return;
    if (result.error != null) {
      emit(state.copyWith(isLoading: false, error: result.error));
    } else {
      final items = result.items!;
      emit(
        state.copyWith(
          items: items,
          isLoading: false,
          hasMore: items.length == pageSize,
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    LoadMoreMediaFilter event,
    Emitter<MediaFiltersState> emit,
  ) async {
    if (state.chatId == null ||
        state.category == null ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    final generation = _generation;
    final previous = state;
    emit(previous.copyWith(isLoadingMore: true, clearError: true));
    final result = await _fetch(
      previous.chatId!,
      previous.category!,
      previous.items.length,
    );
    if (generation != _generation) return;
    if (result.error != null) {
      emit(state.copyWith(isLoadingMore: false, error: result.error));
    } else {
      final items = result.items!;
      emit(
        state.copyWith(
          items: [...previous.items, ...items],
          isLoadingMore: false,
          hasMore: items.length == pageSize,
        ),
      );
    }
  }

  Future<({String? error, List<MediaFilterItem>? items})> _fetch(
    int chatId,
    MediaFilterCategory category,
    int offset,
  ) async {
    final result = switch (category) {
      MediaFilterCategory.photos => await _repository.getPhotos(
        chatId,
        offset: offset,
      ),
      MediaFilterCategory.videos => await _repository.getVideos(
        chatId,
        offset: offset,
      ),
      MediaFilterCategory.files => await _repository.getFiles(
        chatId,
        offset: offset,
      ),
      MediaFilterCategory.audio => await _repository.getAudio(
        chatId,
        offset: offset,
      ),
      MediaFilterCategory.links => await _repository.getLinks(
        chatId,
        offset: offset,
      ),
      MediaFilterCategory.mutualChats => await _repository.getMutualGroups(
        chatId,
        offset: offset,
      ),
    };
    return result.fold(
      (failure) => (error: failure.message, items: null),
      (items) => (error: null, items: List<MediaFilterItem>.from(items)),
    );
  }
}

// presentation/features/media/bloc/media_viewer_state.dart
part of 'media_viewer_bloc.dart';

abstract class MediaViewerState {
  const MediaViewerState();
}

class MediaViewerInitial extends MediaViewerState {}

class MediaViewerLoading extends MediaViewerState {}

class MediaViewerLoaded extends MediaViewerState {
  final List<Message> messages;
  final bool hasMoreMessages;
  final bool isLoadingMore;

  const MediaViewerLoaded({
    required this.messages,
    required this.hasMoreMessages,
    this.isLoadingMore = false,
  });

  MediaViewerLoaded copyWith({
    List<Message>? messages,
    bool? hasMoreMessages,
    bool? isLoadingMore,
  }) {
    return MediaViewerLoaded(
      messages: messages ?? this.messages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class MediaViewerError extends MediaViewerState {
  final String message;

  const MediaViewerError(this.message);
}
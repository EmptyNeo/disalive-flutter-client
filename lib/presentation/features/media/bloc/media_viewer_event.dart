// presentation/features/media/bloc/media_viewer_event.dart
part of 'media_viewer_bloc.dart';

abstract class MediaViewerEvent {}

class LoadInitialMedia extends MediaViewerEvent {
  final int chatId;
  final int? startMessageId;

  LoadInitialMedia({
    required this.chatId,
    this.startMessageId,
  });
}

class LoadMoreMedia extends MediaViewerEvent {
  final int lastMessageId;

  LoadMoreMedia({required this.lastMessageId});
}
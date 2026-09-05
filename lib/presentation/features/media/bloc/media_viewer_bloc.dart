// presentation/features/media/bloc/media_viewer_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/repositories/message_repository.dart';

part 'media_viewer_event.dart';

part 'media_viewer_state.dart';

class MediaViewerBloc extends Bloc<MediaViewerEvent, MediaViewerState> {
  final MessageRepository _messageRepository;
  final int chatId;

  MediaViewerBloc({
    required MessageRepository messageRepository,
    required this.chatId,
  }) : _messageRepository = messageRepository,
       super(MediaViewerInitial()) {
    on<LoadInitialMedia>(_onLoadInitial);
    on<LoadMoreMedia>(_onLoadMore);
  }

  Future<void> _onLoadInitial(
    LoadInitialMedia event,
    Emitter<MediaViewerState> emit,
  ) async {
    emit(MediaViewerLoading());

    // Получаем сообщения из кэша
    final cached = _messageRepository.getCached(chatId);
    if (cached != null && cached.messages.isNotEmpty) {
      emit(MediaViewerLoaded(messages: cached.messages, hasMoreMessages: true));
      return;
    }

    // Если кэша нет, загружаем с сервера
    final result = await _messageRepository.get(
      chatId,
      chatId,
      EntityType.chat,
      60,
      event.startMessageId ?? 0,
      null,
      null,
      null,
    );

    result.fold((failure) => emit(MediaViewerError(failure.message)), (
      response,
    ) {
      _messageRepository.cacheMessages(chatId, response.messages);
      emit(
        MediaViewerLoaded(
          messages: response.messages,
          hasMoreMessages: response.messages.isNotEmpty,
        ),
      );
    });
  }

  Future<void> _onLoadMore(
    LoadMoreMedia event,
    Emitter<MediaViewerState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MediaViewerLoaded) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await _messageRepository.get(
      chatId,
      chatId,
      EntityType.chat,
      60,
      event.lastMessageId,
      null,
      null,
      null,
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (response) {
        if (response.messages.isEmpty) {
          emit(
            currentState.copyWith(isLoadingMore: false, hasMoreMessages: false),
          );
          return;
        }

        // Добавляем новые сообщения в конец (они старше)
        final allMessages = [...currentState.messages, ...response.messages];

        // Удаляем дубликаты
        final uniqueMessages = _removeDuplicates(allMessages);

        emit(
          currentState.copyWith(
            messages: uniqueMessages,
            isLoadingMore: false,
            hasMoreMessages: response.messages.length >= 60,
          ),
        );
      },
    );
  }

  List<Message> _removeDuplicates(List<Message> messages) {
    final uniqueMap = <int, Message>{};
    for (final message in messages) {
      if (message.id != null) {
        uniqueMap[message.id!] = message;
      }
    }
    return uniqueMap.values.toList();
  }
}

// lib/presentation/features/message/bloc/message_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/history_action.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:flutter/cupertino.dart';

part 'message_event.dart';

part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final MessageRepository _messageRepository;

  MessageBloc(this._messageRepository) : super(MessageInitial()) {
    on<GetMessages>(_onGetMessages);
  }

  Future<void> _onGetMessages(
    GetMessages event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageLoading());

    final cachedResponse = _messageRepository.getCached(event.chatId);
    if (cachedResponse != null && cachedResponse.messages.isNotEmpty) {
      emit(
        MessageLoaded(
          messages: cachedResponse.messages,
          actions: cachedResponse.actions,
        ),
      );
    }

    final result = await _messageRepository.get(
      event.chatId,
      event.entityId,
      event.entityType,
      event.limit,
      event.lastIdMessage,
      event.aroundId,
      event.neverThanId,
      event.searchQuery,
    );

    result.fold(
      (failure) {
        if (state is! MessageLoaded) {
          emit(MessageFailure(failure.message));
        }
      },
      (response) {
        emit(
          MessageLoaded(messages: response.messages, actions: response.actions),
        );
      },
    );
  }
}

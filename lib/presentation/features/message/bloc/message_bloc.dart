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
    final bool isInitialLoad =
        event.lastIdMessage == 0 &&
        event.aroundId == null &&
        event.neverThanId == null &&
        event.searchQuery == null;

    if (isInitialLoad) {
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
    } else {
      // Для пагинации показываем текущие сообщения с индикатором загрузки
      final currentState = state;
      if (currentState is MessageLoaded) {
        emit(
          MessageLoaded(
            messages: currentState.messages,
            actions: currentState.actions,
            isLoadingMore: true,
          ),
        );
      }
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
        } else {
          final currentState = state as MessageLoaded;
          emit(
            MessageLoaded(
              messages: currentState.messages,
              actions: currentState.actions,
              isLoadingMore: false,
            ),
          );
        }
      },
      (response) {
        if (isInitialLoad) {
          emit(
            MessageLoaded(
              messages: response.messages,
              actions: response.actions,
            ),
          );
        } else {
          final currentState = state;
          if (currentState is MessageLoaded) {
            final mergedMessages = [
              ...currentState.messages,
              ...response.messages,
            ];
            final uniqueMessages = _removeDuplicates(mergedMessages);

            final mergedActions = [
              ...currentState.actions,
              ...response.actions,
            ];
            final uniqueActions = _removeDuplicateActions(mergedActions);

            emit(
              MessageLoaded(
                messages: uniqueMessages,
                actions: uniqueActions,
                isLoadingMore: false,
              ),
            );
          }
        }
      },
    );
  }

  // Убираем дубликаты сообщений по id
  List<Message> _removeDuplicates(List<Message> messages) {
    final uniqueMap = <int, Message>{};
    for (final message in messages) {
      if (message.id != null) {
        uniqueMap[message.id!] = message;
      }
    }
    return uniqueMap.values.toList();
  }

  // Убираем дубликаты действий по id
  List<HistoryAction> _removeDuplicateActions(List<HistoryAction> actions) {
    final uniqueMap = <int, HistoryAction>{};
    for (final action in actions) {
      if (action.id != null) {
        uniqueMap[action.id!] = action;
      }
    }
    return uniqueMap.values.toList();
  }
}

// lib/presentation/features/message/bloc/message_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/history_action.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:flutter/cupertino.dart';

part 'message_event.dart';

part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final MessageRepository _messageRepository;
  final WsEventBus _eventBus;

  StreamSubscription? _createSubscription;
  StreamSubscription? _updateSubscription;
  StreamSubscription? _deleteSubscription;

  final String tableName = 'Message';

  MessageBloc(this._messageRepository, this._eventBus)
    : super(MessageInitial()) {
    on<GetMessages>(_onGetMessages);
    on<CreateMessage>(_onCreateMessage);

    _setupWsListeners();
  }

  void _setupWsListeners() {
    _createSubscription = _eventBus.subscribe(
      table: 'Message',
      action: ActionType.create,
      onData: (event) {
        final messageData = event.data['message'];
        if (messageData is Map<String, dynamic>) {
          final message = Message.fromMap(messageData);
          final chatId = message.chatId ?? 0;

          add(
            CreateMessage(
              chatId: chatId,
              entityId: chatId,
              entityType: EntityType.chat,
              localGeneratedId: '',
              message: message,
              isWs: true,
            ),
          );
        }
      },
    );
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

  void _handleMessageCreate(WsEvent event) {
    final messageData = event.data['message'];
    if (messageData is Map<String, dynamic>) {
      final message = Message.fromMap(messageData);
      final chatId = message.chatId ?? 0;

      if (chatId == 0) return;

      final cachedResponse = _messageRepository.getCached(chatId);
      if (cachedResponse != null) {
        // Проверяем, нет ли уже такого сообщения
        final exists = cachedResponse.messages.any((m) => m.id == message.id);
        if (!exists) {
          cachedResponse.messages.add(message);
          cachedResponse.messages.sort(
            (a, b) => (a.id ?? 0).compareTo(b.id ?? 0),
          );
        }
      }

      // Обновляем состояние
      final currentState = state;
      if (currentState is MessageLoaded) {
        emit(
          MessageLoaded(
            messages: _messageRepository.getCached(chatId)?.messages ?? [],
            actions: _messageRepository.getCached(chatId)?.actions ?? [],
          ),
        );
      }
    }
  }

  Future<void> _onCreateMessage(
    CreateMessage event,
    Emitter<MessageState> emit,
  ) async {
    if (event.isWs) {
      final message = event.message;
      final chatId = message.chatId ?? event.chatId;

      final cachedResponse = _messageRepository.getCached(chatId);
      if (cachedResponse != null) {
        final exists = cachedResponse.messages.any((m) => m.id == message.id);
        if (!exists) {
          cachedResponse.messages.add(message);
          cachedResponse.messages.sort(
            (a, b) => (a.id ?? 0).compareTo(b.id ?? 0),
          );
        }
      }

      final currentState = state;
      if (currentState is MessageLoaded) {
        emit(
          MessageLoaded(
            messages: _messageRepository.getCached(chatId)?.messages ?? [],
            actions: _messageRepository.getCached(chatId)?.actions ?? [],
          ),
        );
      }
      return;
    }

    final result = await _messageRepository.create(
      event.chatId,
      event.entityId,
      event.entityType,
      event.localGeneratedId,
      event.message.text ?? '',
      event.message.answerMessageId,
      event.message.forwardMessageId,
    );

    result.fold(
      (failure) {
        print('Failed to create message: ${failure.message}');
      },
      (success) {
        // Успех
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

  @override
  Future<void> close() {
    _createSubscription?.cancel();
    return super.close();
  }
}

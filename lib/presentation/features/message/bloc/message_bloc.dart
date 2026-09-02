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
    print("SETUP WS LISTENERS CALLED");
    print("EventBus: $_eventBus");

    _createSubscription = _eventBus.subscribe(
      table: 'Message',
      action: ActionType.create,
      onData: (event) {
        print("START CREATE SUB");
        print(event);
        final messageData = event.data['message'];
        if (messageData is Map<String, dynamic>) {
          final message = Message.fromMap(messageData);
          final chatId = message.chatId ?? 0;

          add(
            CreateMessage(
              chatId: chatId,
              entityId: chatId,
              entityType: EntityType.chat,
              localGeneratedId: event.data['localGeneratedId'] ?? '',
              message: message,
              isWs: true,
            ),
          );
        }
        print("END CREATE SUB");
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

  Future<void> _onCreateMessage(
    CreateMessage event,
    Emitter<MessageState> emit,
  ) async {
    if (event.isWs) {
      // Сообщение пришло из WebSocket — заменяем локальное
      final message = event.message;
      final chatId = message.chatId ?? event.chatId;
      final localGeneratedId = event.localGeneratedId;

      final cachedResponse = _messageRepository.getCached(chatId);
      if (cachedResponse != null) {
        // Ищем локальное сообщение по localGeneratedId
        final localIndex = cachedResponse.messages.indexWhere(
          (m) => m.localGeneratedId == localGeneratedId,
        );

        if (localIndex != -1) {
          // Заменяем локальное на серверное
          cachedResponse.messages[localIndex] = message;
        } else {
          // Если локального нет — проверяем, нет ли уже такого сообщения
          final exists = cachedResponse.messages.any((m) => m.id == message.id);
          // В _onCreateMessage, когда добавляем из WebSocket:
          if (!exists) {
            cachedResponse.messages.insert(0, message);
          }
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

    // HTTP запрос — отправляем на сервер и сразу показываем локальное сообщение
    final message = event.message;
    final chatId = event.chatId;

    // Добавляем локальное сообщение в кэш
    final cachedResponse = _messageRepository.getCached(chatId);
    if (cachedResponse != null) {
      // Ищем сообщение с тем же localGeneratedId
      final existingIndex = cachedResponse.messages.indexWhere(
        (m) => m.localGeneratedId == event.localGeneratedId,
      );

      if (existingIndex != -1) {
        cachedResponse.messages[existingIndex] = cachedResponse
            .messages[existingIndex]
            .copyWith(hasError: false);
      } else {
        cachedResponse.messages.insert(0, message);
      }
    } else {
      _messageRepository.cacheMessages(chatId, [message]);
    }

    // Обновляем UI с локальным сообщением
    final currentState = state;
    if (currentState is MessageLoaded) {
      emit(
        MessageLoaded(
          messages: _messageRepository.getCached(chatId)?.messages ?? [],
          actions: _messageRepository.getCached(chatId)?.actions ?? [],
        ),
      );
    }

    // Отправляем на сервер
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

        // Помечаем сообщение как ошибочное
        final cachedResponse = _messageRepository.getCached(chatId);
        if (cachedResponse != null) {
          final index = cachedResponse.messages.indexWhere(
            (m) => m.localGeneratedId == event.localGeneratedId,
          );
          if (index != -1) {
            cachedResponse.messages[index] = cachedResponse.messages[index]
                .copyWith(hasError: true);
          }
        }

        // Обновляем UI с ошибкой
        final currentState = state;
        if (currentState is MessageLoaded) {
          emit(
            MessageLoaded(
              messages: _messageRepository.getCached(chatId)?.messages ?? [],
              actions: _messageRepository.getCached(chatId)?.actions ?? [],
            ),
          );
        }
      },
      (success) {
        // Успех — сообщение придет через WebSocket и заменит локальное
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

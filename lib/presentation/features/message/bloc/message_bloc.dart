// lib/presentation/features/message/bloc/message_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/history_action.dart';
import 'package:disalive/domain/models/ui/message_grouped.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/utils/ui/message_grouper.dart';
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
    on<DeleteMessage>(_onDeleteMessage);
    on<UpdateMessage>(_onUpdateMessage);

    _setupWsListeners();
  }

  void _setupWsListeners() {
    _createSubscription = _eventBus.subscribe(
      table: tableName,
      action: ActionType.create,
      onData: _onWsCreateEvent,
    );

    _updateSubscription = _eventBus.subscribe(
      table: tableName,
      action: ActionType.update,
      onData: _onWsUpdateEvent,
    );

    _deleteSubscription = _eventBus.subscribe(
      table: tableName,
      action: ActionType.delete,
      onData: _onWsDeleteEvent,
    );
  }

  void _onWsCreateEvent(WsEvent event) {
    final messageData = event.data['message'];
    if (messageData is! Map<String, dynamic>) return;

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

  void _onWsUpdateEvent(WsEvent event) {
    final messageData = event.data['message'];
    if (messageData is! Map<String, dynamic>) return;

    final message = Message.fromMap(messageData);
    final chatId = message.chatId ?? 0;

    add(
      UpdateMessage(
        chatId: chatId,
        entityId: chatId,
        entityType: EntityType.chat,
        message: message,
        isWs: true,
      ),
    );
  }

  void _onWsDeleteEvent(WsEvent event) {
    final messageId = event.data['messageId'] ?? event.data['id'];
    final chatId = event.data['chatId'];

    if (messageId == null || chatId == null) return;

    add(
      DeleteMessage(
        chatId: chatId,
        entityId: chatId,
        entityType: EntityType.chat,
        messageId: messageId,
        isWs: true,
      ),
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
            hasMoreMessages: cachedResponse.messages.isNotEmpty,
            isLoadingMore: false, // Явно указываем
          ),
        );
        return;
      }
    } else {
      final currentState = state;
      if (currentState is MessageLoaded) {
        final cached = _messageRepository.getCached(event.chatId);
        if (cached != null && cached.messages.isNotEmpty) {
          final oldestId = event.lastIdMessage;

          final olderMessages =
              cached.messages
                  .where((m) => (m.id ?? 0) < oldestId && (m.id ?? 0) > 0)
                  .toList()
                ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

          if (olderMessages.isNotEmpty) {
            final mergedMessages = [...currentState.messages, ...olderMessages];
            final uniqueMessages = _removeDuplicates(mergedMessages);

            // Даже если showed == false, мы должны обновить состояние,
            // чтобы слушатели (MediaViewer) знали, что данные есть.
            emit(
              MessageLoaded(
                messages: uniqueMessages,
                actions: currentState.actions,
                isLoadingMore: false, // Сбрасываем флаг загрузки!
                hasMoreMessages: true,
              ),
            );
            return;
          }
        }

        // Если старых сообщений нет в кэше, мы все равно должны эмитить isLoadingMore: true,
        // иначе UI не будет знать, что процесс пошел (опционально, но безопасно)
        emit(
          MessageLoaded(
            messages: currentState.messages,
            actions: currentState.actions,
            isLoadingMore: true,
          ),
        );
      }
    }

    // Запрашиваем сервер
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
        // ВАЖНО: Даже при ошибке и showed: false мы должны сбросить флаг загрузки,
        // иначе интерфейс зависнет навсегда.
        if (state is! MessageLoaded) {
          emit(MessageFailure(failure.message));
        } else {
          final currentState = state as MessageLoaded;
          emit(
            MessageLoaded(
              messages: currentState.messages,
              actions: currentState.actions,
              isLoadingMore: false, // Сбрасываем флаг
            ),
          );
        }
      },
      (response) {
        if (isInitialLoad) {
          _messageRepository.cacheMessages(event.chatId, response.messages);

          emit(
            MessageLoaded(
              messages: response.messages,
              actions: response.actions,
              hasMoreMessages: response.messages.isNotEmpty,
              isLoadingMore: false,
            ),
          );
        } else {
          final currentState = state;
          if (currentState is MessageLoaded) {
            if (response.messages.isEmpty) {
              emit(
                MessageLoaded(
                  messages: currentState.messages,
                  actions: currentState.actions,
                  isLoadingMore: false,
                  hasMoreMessages: false, // Сообщения действительно закончились
                ),
              );
              return;
            }

            final mergedMessages = [
              ...currentState.messages,
              ...response.messages,
            ];
            final uniqueMessages = _removeDuplicates(mergedMessages);

            _messageRepository.cacheMessages(event.chatId, uniqueMessages);

            emit(
              MessageLoaded(
                messages: uniqueMessages,
                actions: currentState.actions,
                isLoadingMore: false, // Критически важно сбросить этот флаг!
                hasMoreMessages:
                    response.messages.length >=
                    event.limit, // Более точная проверка
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
      _applyIncomingServerMessage(event);
      _emitFromCache(_wsChatId(event), emit);
      return;
    }

    _addOptimisticLocalMessage(event);
    _emitFromCache(event.chatId, emit);

    final result = await _messageRepository.create(
      event.chatId,
      event.entityId,
      event.entityType,
      event.localGeneratedId,
      event.message.text ?? '',
      event.message.answerMessageId,
      event.message.forwardMessageId,
    );

    result.fold((failure) {
      debugPrint('Failed to create message: ${failure.message}');
      _markLocalMessageAsFailed(event.chatId, event.localGeneratedId);
      _emitFromCache(event.chatId, emit);
    }, (_) {});
  }

  // --- Кэш сообщений чата: три чётких сценария ---

  void _applyIncomingServerMessage(CreateMessage event) {
    final message = event.message;
    final chatId = _wsChatId(event);
    final cached = _messageRepository.getCached(chatId);
    if (cached == null) return;

    final localIndex = cached.messages.indexWhere(
      (m) => m.localGeneratedId == event.localGeneratedId,
    );

    if (localIndex != -1) {
      cached.messages[localIndex] = message;
      return;
    }

    final alreadyExists = cached.messages.any((m) => m.id == message.id);
    if (!alreadyExists) {
      cached.messages.insert(0, message);
    }
  }

  Future<void> _onUpdateMessage(
    UpdateMessage event,
    Emitter<MessageState> emit,
  ) async {
    if (event.isWs) {
      _updateMessageFromWs(event);
      _emitFromCache(event.chatId, emit);
      return;
    }

    // Помечаем сообщение как обновляемое
    _markMessageAsLoading(
      event.chatId,
      event.message.id ?? 0,
      ActionType.update,
    );
    _emitFromCache(event.chatId, emit);

    final result = await _messageRepository.update(
      event.chatId,
      event.entityId,
      event.entityType,
      event.message.id ?? 0,
      event.message.text ?? '',
    );

    result.fold((failure) {
      debugPrint('Failed to update message: ${failure.message}');
      _markMessageAsFailed(
        event.chatId,
        event.message.id ?? 0,
        ActionType.update,
      );
      _emitFromCache(event.chatId, emit);
    }, (_) {});
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<MessageState> emit,
  ) async {
    if (event.isWs) {
      _removeMessageFromCache(event.chatId, event.messageId);
      _emitFromCache(event.chatId, emit);
      return;
    }

    // Помечаем сообщение как удаляемое (показываем индикатор)
    _markMessageAsLoading(event.chatId, event.messageId, ActionType.delete);
    _emitFromCache(event.chatId, emit);

    final result = await _messageRepository.delete(
      event.chatId,
      event.entityId,
      event.entityType,
      event.messageId,
    );

    result.fold(
      (failure) {
        debugPrint('Failed to delete message: ${failure.message}');
        // Ошибка удаления — показываем ошибку
        _markMessageAsFailed(event.chatId, event.messageId, ActionType.delete);
        _emitFromCache(event.chatId, emit);
      },
      (_) {
        // Успех — удаляем из кэша
        _removeMessageFromCache(event.chatId, event.messageId);
        _emitFromCache(event.chatId, emit);
      },
    );
  }

  void _addOptimisticLocalMessage(CreateMessage event) {
    final chatId = event.chatId;
    final cached = _messageRepository.getCached(chatId);

    if (cached == null) {
      final messageWithLoading = event.message.copyWith(
        hasLoading: ActionType.create,
      );
      _messageRepository.cacheMessages(chatId, [messageWithLoading]);
      return;
    }

    final existingIndex = cached.messages.indexWhere(
      (m) => m.localGeneratedId == event.localGeneratedId,
    );

    if (existingIndex != -1) {
      cached.messages[existingIndex] = cached.messages[existingIndex].copyWith(
        hasError: null,
        hasLoading: ActionType.create,
      );
    } else {
      cached.messages.insert(
        0,
        event.message.copyWith(hasLoading: ActionType.create),
      );
    }
  }

  void _markLocalMessageAsFailed(int chatId, String localGeneratedId) {
    final cached = _messageRepository.getCached(chatId);
    if (cached == null) return;

    final index = cached.messages.indexWhere(
      (m) => m.localGeneratedId == localGeneratedId,
    );
    if (index != -1) {
      cached.messages[index] = cached.messages[index].copyWith(
        hasError: ActionType.create,
        hasLoading: null,
      );
    }
  }

  void _markMessageAsFailed(int chatId, int messageId, ActionType action) {
    final cached = _messageRepository.getCached(chatId);
    if (cached == null) return;

    final index = cached.messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      cached.messages[index] = cached.messages[index].copyWith(
        hasError: action,
        hasLoading: null,
      );
    }
  }

  void _markMessageAsLoading(int chatId, int messageId, ActionType action) {
    final cached = _messageRepository.getCached(chatId);
    if (cached == null) return;

    final index = cached.messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      cached.messages[index] = cached.messages[index].copyWith(
        hasLoading: action,
        hasError: null,
      );
    }
  }

  int _wsChatId(CreateMessage event) => event.message.chatId ?? event.chatId;

  void _emitFromCache(int chatId, Emitter<MessageState> emit) {
    if (state is! MessageLoaded) return;
    final cached = _messageRepository.getCached(chatId);

    emit(
      MessageLoaded(
        messages: cached?.messages ?? [],
        actions: cached?.actions ?? [],
      ),
    );
  }

  void _updateMessageFromWs(UpdateMessage event) {
    final message = event.message;
    final chatId = message.chatId ?? event.chatId;
    final cached = _messageRepository.getCached(chatId);
    if (cached == null) return;

    final index = cached.messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      cached.messages[index] = message;
    }
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

  List<HistoryAction> _removeDuplicateActions(List<HistoryAction> actions) {
    final uniqueMap = <int, HistoryAction>{};
    for (final action in actions) {
      if (action.id != null) {
        uniqueMap[action.id!] = action;
      }
    }
    return uniqueMap.values.toList();
  }

  void _removeMessageFromCache(int chatId, int messageId) {
    final cached = _messageRepository.getCached(chatId);
    if (cached == null) return;

    cached.messages.removeWhere((m) => m.id == messageId);
  }

  @override
  Future<void> close() {
    _createSubscription?.cancel();
    _updateSubscription?.cancel();
    _deleteSubscription?.cancel();
    return super.close();
  }
}

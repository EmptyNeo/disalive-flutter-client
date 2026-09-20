// lib/presentation/features/message/bloc/message_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
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
  final ChatRepository _chatRepository;
  final WsEventBus _eventBus;

  StreamSubscription? _createSubscription;
  StreamSubscription? _updateSubscription;
  StreamSubscription? _deleteSubscription;

  final String tableName = 'Message';

  MessageBloc(this._messageRepository, this._chatRepository, this._eventBus)
    : super(MessageInitial()) {
    on<GetMessages>(_onGetMessages);
    on<CreateMessage>(_onCreateMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<UpdateMessage>(_onUpdateMessage);
  }

  void setupListeners() {
    closeSubs();

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

  List<Message> _ensureDescendingOrder(List<Message> messages) {
    final sorted = List<Message>.from(messages);
    sorted.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return sorted;
  }

  Future<void> _onGetMessages(
    GetMessages event,
    Emitter<MessageState> emit,
  ) async {
    final bool isInitialLoad =
        event.lastIdMessage == 0 &&
        event.aroundId == null &&
        event.newerThanId == null &&
        event.searchQuery == null;

    final bool isAroundLoad = event.aroundId != null;
    final bool isNewerLoad = event.newerThanId != null;
    final bool isOlderLoad = event.lastIdMessage > 0;

    if (isInitialLoad || isAroundLoad) {
      emit(MessageLoading());

      // 🎯 1. ЖЕСТКОЕ ОГРАНИЧЕНИЕ ДЛЯ КЭША ПРИ aroundId
      if (isAroundLoad) {
        final cachedResponse = _messageRepository.getCached(event.chatId);
        if (cachedResponse != null && cachedResponse.messages.isNotEmpty) {
          // Пытаемся найти aroundId в кэше
          final aroundIndex = cachedResponse.messages.indexWhere(
            (m) => m.id == event.aroundId,
          );

          if (aroundIndex != -1) {
            // 🎯 ДЕЛАЕМ СРЕЗ (WINDOW) ИЗ КЭША!
            // Берём не более event.limit сообщений вокруг aroundId.
            // Так как список отсортирован DESC, "новее" = меньшие индексы, "старше" = большие.
            final halfLimit = event.limit ~/ 2;
            final start = (aroundIndex - halfLimit).clamp(
              0,
              cachedResponse.messages.length,
            );
            final end = (aroundIndex + halfLimit + 1).clamp(
              0,
              cachedResponse.messages.length,
            );

            final slicedMessages = cachedResponse.messages.sublist(start, end);

            emit(
              MessageLoaded(
                messages: slicedMessages,
                // Эмитим ТОЛЬКО срез, а не все 50+ сообщений!
                actions: cachedResponse.actions,
                hasMoreMessages: true,
                // Всегда true, так как мы показали только часть
                isLoadingMore: false,
                isLoadingNewer: false,
              ),
            );
            return; // Прерываем, на сервер идти не нужно, у нас уже есть нужный диапазон
          }
        }
      }

      // Если это isInitialLoad или aroundId не найден в кэше, идём на сервер
      final result = await _messageRepository.get(
        event.chatId,
        event.entityId,
        event.entityType,
        event.limit,
        event.lastIdMessage,
        event.aroundId,
        event.newerThanId,
        event.searchQuery,
      );

      result.fold(
        (failure) {
          emit(MessageFailure(failure));
        },
        (response) {
          final serverMessages = _ensureDescendingOrder(response.messages);

          List<Message> finalMessages;

          if (isAroundLoad) {
            final targetIndex = serverMessages.indexWhere(
              (m) => m.id == event.aroundId,
            );

            if (targetIndex != -1) {
              final halfLimit = event.limit ~/ 2;
              final start = (targetIndex - halfLimit).clamp(
                0,
                serverMessages.length,
              );
              final end = (targetIndex + halfLimit + 1).clamp(
                0,
                serverMessages.length,
              );
              finalMessages = serverMessages.sublist(start, end);
            } else {
              // Если сообщение вдруг удалено и его нет в ответе, берем просто лимит
              finalMessages = serverMessages.length > event.limit
                  ? serverMessages.sublist(0, event.limit)
                  : serverMessages;
            }
          } else {
            // 🎯 Стандартная обрезка для isInitialLoad (берем самые последние)
            finalMessages = serverMessages.length > event.limit
                ? serverMessages.sublist(0, event.limit)
                : serverMessages;
          }

          _messageRepository.cacheMessages(event.chatId, finalMessages);

          emit(
            MessageLoaded(
              messages: finalMessages,
              actions: response.actions,
              hasMoreMessages: finalMessages.isNotEmpty,
              isLoadingMore: false,
              isLoadingNewer: false,
            ),
          );
          return;
        },
      );
    } else {
      // Логика для isNewerLoad и isOlderLoad (пагинация) остаётся без изменений
      final currentState = state;
      if (currentState is MessageLoaded) {
        if (isOlderLoad) {
          final cached = _messageRepository.getCached(event.chatId);
          if (cached != null && cached.messages.isNotEmpty) {
            final olderMessages =
                cached.messages
                    .where(
                      (m) =>
                          (m.id ?? 0) < event.lastIdMessage && (m.id ?? 0) > 0,
                    )
                    .toList()
                  ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

            if (olderMessages.isNotEmpty) {
              final merged = [...currentState.messages, ...olderMessages];
              emit(
                MessageLoaded(
                  messages: _removeDuplicates(merged),
                  actions: currentState.actions,
                  isLoadingMore: false,
                  isLoadingNewer: false,
                  hasMoreMessages: currentState.hasMoreMessages,
                ),
              );
              return;
            }
          }
        }

        emit(
          MessageLoaded(
            messages: currentState.messages,
            actions: currentState.actions,
            isLoadingMore: isOlderLoad,
            isLoadingNewer: isNewerLoad,
          ),
        );
      } else {
        emit(MessageLoading());
      }

      final result = await _messageRepository.get(
        event.chatId,
        event.entityId,
        event.entityType,
        event.limit,
        event.lastIdMessage,
        event.aroundId,
        event.newerThanId,
        event.searchQuery,
      );

      result.fold(
        (failure) {
          if (state is! MessageLoaded) {
            emit(MessageFailure(failure));
          } else {
            final currentState = state as MessageLoaded;
            emit(
              MessageLoaded(
                messages: currentState.messages,
                actions: currentState.actions,
                isLoadingMore: false,
                isLoadingNewer: false,
              ),
            );
          }
        },
        (response) {
          final serverMessages = _ensureDescendingOrder(response.messages);
          final currentState = state;

          if (currentState is! MessageLoaded) {
            _messageRepository.cacheMessages(event.chatId, serverMessages);
            emit(
              MessageLoaded(
                messages: serverMessages,
                actions: response.actions,
                hasMoreMessages: serverMessages.isNotEmpty,
                isLoadingMore: false,
                isLoadingNewer: false,
              ),
            );
            return;
          }

          if (serverMessages.isEmpty) {
            emit(
              MessageLoaded(
                messages: currentState.messages,
                actions: currentState.actions,
                isLoadingMore: false,
                isLoadingNewer: false,
                hasMoreMessages: isNewerLoad
                    ? currentState.hasMoreMessages
                    : false,
              ),
            );
            return;
          }

          final mergedMessages = isNewerLoad
              ? [...serverMessages, ...currentState.messages]
              : [...currentState.messages, ...serverMessages];

          final uniqueMessages = _removeDuplicates(mergedMessages);
          _messageRepository.cacheMessages(event.chatId, uniqueMessages);

          emit(
            MessageLoaded(
              messages: uniqueMessages,
              actions: currentState.actions,
              isLoadingMore: false,
              isLoadingNewer: false,
              hasMoreMessages: isNewerLoad
                  ? currentState.hasMoreMessages
                  : (serverMessages.length >= event.limit),
            ),
          );
        },
      );
    }
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
      event.message,
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
      event.message,
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
    if (event.localGeneratedId != null) {
      _removeLocalMessageFromCache(event.chatId, event.localGeneratedId!);
      _emitFromCache(event.chatId, emit);
      return;
    }

    if (event.isWs) {
      _removeMessageFromCache(event.chatId, event.messageId!);
      _emitFromCache(event.chatId, emit);
      return;
    }

    final targetMessageId = event.messageId!;

    _markMessageAsLoading(event.chatId, targetMessageId, ActionType.delete);
    _emitFromCache(event.chatId, emit);

    final result = await _messageRepository.delete(
      event.chatId,
      event.entityId,
      event.entityType,
      targetMessageId,
    );

    result.fold(
      (failure) {
        debugPrint('Failed to delete message: ${failure.message}');
        _markMessageAsFailed(event.chatId, targetMessageId, ActionType.delete);
        _emitFromCache(event.chatId, emit);
      },
      (_) {
        _removeMessageFromCache(event.chatId, targetMessageId);
        _emitFromCache(event.chatId, emit);
      },
    );
  }

  void _removeLocalMessageFromCache(int chatId, String localGeneratedId) {
    final cached = _messageRepository.getCached(chatId);
    if (cached == null) return;

    cached.messages.removeWhere((m) => m.localGeneratedId == localGeneratedId);
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

    if (!_chatRepository.isCurrentChat(chatId)) return;

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
    closeSubs();
    _messageRepository.clearAllCache();
    return super.close();
  }

  void closeSubs() {
    _createSubscription?.cancel();
    _updateSubscription?.cancel();
    _deleteSubscription?.cancel();
  }
}

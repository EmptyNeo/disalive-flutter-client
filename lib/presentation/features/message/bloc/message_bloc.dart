// lib/presentation/features/message/bloc/message_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/history_action.dart';
import 'package:disalive/domain/models/reaction_message.dart';
import 'package:disalive/domain/models/responses/symbol_data.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/reactions_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:flutter/cupertino.dart';

part 'message_event.dart';

part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final MessageRepository _messageRepository;
  final ReactionsRepository _reactionsRepository;
  final ChatRepository _chatRepository;
  final WsEventBus _eventBus;

  StreamSubscription? _createSubscription;
  StreamSubscription? _updateSubscription;
  StreamSubscription? _deleteSubscription;

  StreamSubscription? _reactionCreateSubscription;
  StreamSubscription? _reactionDeleteSubscription;
  StreamSubscription? _historyCreateSubscription;
  StreamSubscription? _historyUpdateSubscription;
  final Map<int, List<List<Message>>> _messagesDuringLoad = {};
  final Map<int, List<List<HistoryAction>>> _actionsDuringLoad = {};
  int? _activeChatId;
  int? _activeEntityId;
  EntityType? _activeEntityType;

  final String tableName = 'Message';
  final String reactionTableName = 'ReactionsMessage';

  MessageBloc(
    this._messageRepository,
    this._reactionsRepository,
    this._chatRepository,
    this._eventBus,
  ) : super(MessageInitial()) {
    on<GetMessages>(_onGetMessages);
    on<CreateMessage>(_onCreateMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<UpdateMessage>(_onUpdateMessage);
    on<ToggleReaction>(_onToggleReaction);
    on<UpdateReactionFromWs>(_onUpdateReactionFromWs);
    on<UpsertHistoryAction>(_onUpsertHistoryAction);
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

    _reactionCreateSubscription = _eventBus.subscribe(
      table: reactionTableName,
      action: ActionType.create,
      onData: (event) => _dispatchReactionEvent(event, isCreate: true),
    );

    _reactionDeleteSubscription = _eventBus.subscribe(
      table: reactionTableName,
      action: ActionType.delete,
      onData: (event) => _dispatchReactionEvent(event, isCreate: false),
    );

    _historyCreateSubscription = _eventBus.subscribe(
      table: 'HistoryActions',
      action: ActionType.create,
      onData: _onWsHistoryAction,
    );
    _historyUpdateSubscription = _eventBus.subscribe(
      table: 'HistoryActions',
      action: ActionType.update,
      onData: _onWsHistoryAction,
    );
  }

  void _onWsHistoryAction(WsEvent event) {
    final raw = event.data['action'];
    if (raw is! Map) return;
    final data = Map<String, dynamic>.from(raw);
    final entityId = DataParser.parseInt(
      data['entityId'] ?? event.data['entityId'],
    );
    final entityType = EntityType.fromString(
      (data['entityType'] ?? event.data['entityType'])?.toString(),
    );
    final chatId = _activeChatId;
    if (chatId == null ||
        entityId != _activeEntityId ||
        entityType != _activeEntityType) {
      return;
    }
    data['id'] = DataParser.parseInt(data['id']);
    if (data['id'] == null) return;
    data['entityId'] = entityId;
    data['lastIdMessage'] = DataParser.parseInt(data['lastIdMessage']);
    data['startTimestamp'] = DataParser.parseInt(data['startTimestamp']);
    add(
      UpsertHistoryAction(chatId: chatId, action: HistoryAction.fromMap(data)),
    );
  }

  void _onUpsertHistoryAction(
    UpsertHistoryAction event,
    Emitter<MessageState> emit,
  ) {
    for (final pending
        in _actionsDuringLoad[event.chatId] ?? const <List<HistoryAction>>[]) {
      pending.add(event.action);
    }
    final cached = _messageRepository.getCached(event.chatId);
    final merged = _mergeActions(cached?.actions ?? const [], [event.action]);
    _messageRepository.cacheActions(event.chatId, merged);
    if (_activeChatId == event.chatId && state is MessageLoaded) {
      final loaded = state as MessageLoaded;
      emit(
        loaded.copyWith(actions: _mergeActions(loaded.actions, [event.action])),
      );
    }
  }

  List<HistoryAction> _mergeActions(
    List<HistoryAction> existing,
    List<HistoryAction> incoming,
  ) {
    final byId = <int, HistoryAction>{};
    for (final action in [...existing, ...incoming]) {
      if (action.id != null) byId[action.id!] = action;
    }
    return byId.values.toList()
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
  }

  void _onWsCreateEvent(WsEvent event) {
    final message = _messageFromWs(event);
    final chatId = message?.chatId;
    if (message == null || chatId == null) return;
    for (final pending
        in _messagesDuringLoad[chatId] ?? const <List<Message>>[]) {
      pending.add(message);
    }

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
    final message = _messageFromWs(event);
    final chatId = message?.chatId;
    if (message == null || chatId == null) return;

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
    final messageId = DataParser.parseInt(
      event.data['messageId'] ?? event.data['id'],
    );
    final chatId = DataParser.parseInt(event.data['chatId']);

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

  Message? _messageFromWs(WsEvent event) {
    final rawMessage = event.data['message'];
    if (rawMessage is! Map) return null;
    final data = Map<String, dynamic>.from(rawMessage);
    final chatId = DataParser.parseInt(data['chatId'] ?? event.data['chatId']);
    final id = DataParser.parseInt(data['id']);
    if (chatId == null || id == null) return null;
    data['chatId'] = chatId;
    data['id'] = id;
    return Message.fromMap(data);
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
    _activeChatId = event.chatId;
    _activeEntityId = event.entityId;
    _activeEntityType = event.entityType;
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

      if (isAroundLoad) {
        final cachedResponse = _messageRepository.getCached(event.chatId);
        if (cachedResponse != null && cachedResponse.messages.isNotEmpty) {
          if (cachedResponse.messages.any((m) => m.id == event.aroundId)) {
            emit(
              MessageLoaded(
                messages: _ensureDescendingOrder(cachedResponse.messages),
                actions: cachedResponse.actions,
                hasMoreMessages: true,
                hasNewerMessages: true,
                isLoadingMore: false,
                isLoadingNewer: false,
              ),
            );
            return;
          }
        }
      }

      final pendingMessages = <Message>[];
      final pendingActions = <HistoryAction>[];
      final cachedActions =
          _messageRepository.getCached(event.chatId)?.actions ??
          const <HistoryAction>[];
      (_messagesDuringLoad[event.chatId] ??= []).add(pendingMessages);
      (_actionsDuringLoad[event.chatId] ??= []).add(pendingActions);
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
      final activeLoads = _messagesDuringLoad[event.chatId];
      activeLoads?.remove(pendingMessages);
      if (activeLoads?.isEmpty ?? false) {
        _messagesDuringLoad.remove(event.chatId);
      }
      final activeActionLoads = _actionsDuringLoad[event.chatId];
      activeActionLoads?.remove(pendingActions);
      if (activeActionLoads?.isEmpty ?? false) {
        _actionsDuringLoad.remove(event.chatId);
      }

      result.fold(
        (failure) {
          emit(MessageFailure(failure));
        },
        (response) {
          final serverMessages = _ensureDescendingOrder(
            _removeDuplicates([...response.messages, ...pendingMessages]),
          );
          List<Message> finalMessages;

          if (isAroundLoad) {
            finalMessages = serverMessages;
          } else {
            finalMessages = serverMessages.length > event.limit
                ? serverMessages.sublist(0, event.limit)
                : serverMessages;
          }

          final cachedMessages = isAroundLoad
              ? _messageRepository.getCached(event.chatId)?.messages ??
                    const <Message>[]
              : const <Message>[];
          _messageRepository.cacheMessages(
            event.chatId,
            _ensureDescendingOrder(
              _removeDuplicates([
                ...cachedMessages,
                ...finalMessages,
                ...pendingMessages,
              ]),
            ),
          );

          final actions = _mergeActions(
            _mergeActions(cachedActions, response.actions),
            pendingActions,
          );
          _messageRepository.cacheActions(event.chatId, actions);

          emit(
            MessageLoaded(
              messages: finalMessages,
              actions: actions,
              hasMoreMessages: isAroundLoad
                  ? true
                  : (response.messages.length >= event.limit),
              hasNewerMessages: isAroundLoad ? true : false,
              isLoadingMore: false,
              isLoadingNewer: false,
            ),
          );
          return;
        },
      );
    } else {
      final currentState = state;
      if (currentState is MessageLoaded) {
        if (isOlderLoad &&
            (currentState.isLoadingMore || !currentState.hasMoreMessages)) {
          return;
        }
        if (isNewerLoad && currentState.isLoadingNewer) return;
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
              final uniqueMessages = _removeDuplicates(merged);
              final addedCount =
                  uniqueMessages.length - currentState.messages.length;
              if (addedCount > 0) {
                emit(
                  MessageLoaded(
                    messages: uniqueMessages,
                    actions: currentState.actions,
                    isLoadingMore: false,
                    isLoadingNewer: false,
                    hasMoreMessages: currentState.hasMoreMessages,
                    hasNewerMessages: currentState.hasNewerMessages,
                  ),
                );
                return;
              }
            }
          }
        }

        emit(
          MessageLoaded(
            messages: currentState.messages,
            actions: currentState.actions,
            isLoadingMore: isOlderLoad,
            isLoadingNewer: isNewerLoad,
            hasMoreMessages: currentState.hasMoreMessages,
            hasNewerMessages: currentState.hasNewerMessages,
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
                hasMoreMessages: currentState.hasMoreMessages,
                hasNewerMessages: currentState.hasNewerMessages,
              ),
            );
          }
        },
        (response) {
          final serverMessages = _ensureDescendingOrder(response.messages);
          final currentState = state;

          if (currentState is! MessageLoaded) {
            _messageRepository.cacheMessages(event.chatId, serverMessages);
            _messageRepository.cacheActions(event.chatId, response.actions);
            emit(
              MessageLoaded(
                messages: serverMessages,
                actions: response.actions,
                hasMoreMessages: serverMessages.length >= event.limit,
                hasNewerMessages: isNewerLoad
                    ? (serverMessages.length >= event.limit)
                    : true,
                isLoadingMore: false,
                isLoadingNewer: false,
              ),
            );
            return;
          }

          if (serverMessages.isEmpty) {
            final actions = _mergeActions(
              currentState.actions,
              response.actions,
            );
            _messageRepository.cacheActions(event.chatId, actions);
            emit(
              MessageLoaded(
                messages: currentState.messages,
                actions: actions,
                isLoadingMore: false,
                isLoadingNewer: false,
                hasMoreMessages: isOlderLoad
                    ? false
                    : currentState.hasMoreMessages,
                hasNewerMessages: isNewerLoad
                    ? false
                    : currentState.hasNewerMessages,
              ),
            );
            return;
          }

          final mergedMessages = isNewerLoad
              ? [...serverMessages, ...currentState.messages]
              : [...currentState.messages, ...serverMessages];

          final uniqueMessages = _removeDuplicates(mergedMessages);
          final addedCount =
              uniqueMessages.length - currentState.messages.length;
          _messageRepository.cacheMessages(event.chatId, uniqueMessages);
          final actions = _mergeActions(currentState.actions, response.actions);
          _messageRepository.cacheActions(event.chatId, actions);

          emit(
            MessageLoaded(
              messages: uniqueMessages,
              actions: actions,
              isLoadingMore: false,
              isLoadingNewer: false,
              hasMoreMessages: isNewerLoad
                  ? currentState.hasMoreMessages
                  : (serverMessages.length >= event.limit && addedCount > 0),
              hasNewerMessages: isNewerLoad
                  ? (serverMessages.length >= event.limit && addedCount > 0)
                  : currentState.hasNewerMessages,
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
      event.symbolData?.filePath,
      event.symbolData?.typeFile,
      event.symbolData?.packId,
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
    if (cached == null) {
      _messageRepository.cacheMessages(chatId, [message]);
      return;
    }
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
    final currentState = state as MessageLoaded;
    final cached = _messageRepository.getCached(chatId);

    if (!_chatRepository.isCurrentChat(chatId)) return;

    emit(
      MessageLoaded(
        messages: cached?.messages ?? [],
        actions: cached?.actions ?? [],
        isLoadingMore: currentState.isLoadingMore,
        isLoadingNewer: currentState.isLoadingNewer,
        hasMoreMessages: currentState.hasMoreMessages,
        hasNewerMessages: currentState.hasNewerMessages,
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

  void _removeMessageFromCache(int chatId, int messageId) {
    final cached = _messageRepository.getCached(chatId);
    if (cached == null) return;

    cached.messages.removeWhere((m) => m.id == messageId);
  }

  Future<void> _onToggleReaction(
    ToggleReaction event,
    Emitter<MessageState> emit,
  ) async {
    final cached = _messageRepository.getCached(event.chatId);

    // Если кэша нет, просто делаем запрос к API (fallback)
    if (cached == null) {
      await _doApiToggle(event);
      return;
    }

    final msgIndex = cached.messages.indexWhere((m) => m.id == event.messageId);
    if (msgIndex == -1) {
      await _doApiToggle(event);
      return;
    }

    // 1. СОХРАНЯЕМ исходное состояние для возможного отката (rollback)
    final originalMsg = cached.messages[msgIndex];
    final currentReactions = originalMsg.reactions ?? [];
    final reactionIndex = currentReactions.indexWhere(
      (r) => r.nameReaction == event.nameReaction,
    );

    List<ReactionMessage> newReactions = List.from(currentReactions);

    // 2. ОПТИМИСТИЧНО обновляем кэш
    if (reactionIndex != -1) {
      final existing = currentReactions[reactionIndex];
      if (existing.hasUserReaction ?? false) {
        // Пользователь УДАЛЯЕТ реакцию
        final newAmount = (existing.amount ?? 1) - 1;
        if (newAmount <= 0) {
          newReactions.removeAt(reactionIndex);
        } else {
          newReactions[reactionIndex] = existing.copyWith(
            amount: newAmount,
            hasUserReaction: false,
          );
        }
      } else {
        // Пользователь ДОБАВЛЯЕТ реакцию к уже существующей
        newReactions[reactionIndex] = existing.copyWith(
          amount: (existing.amount ?? 0) + 1,
          hasUserReaction: true,
        );
      }
    } else {
      // Реакции не было, добавляем новую
      newReactions.add(
        ReactionMessage(
          messageId: event.messageId,
          nameReaction: event.nameReaction,
          amount: 1,
          hasUserReaction: true,
        ),
      );
    }

    // Применяем изменения в кэш
    cached.messages[msgIndex] = originalMsg.copyWith(
      reactions: newReactions,
      clearReactions: newReactions.isEmpty,
    );
    _messageRepository.cacheMessages(event.chatId, cached.messages);

    // 3. Мгновенно эмитим новое состояние, если мы в этом чате
    if (_chatRepository.isCurrentChat(event.chatId) && state is MessageLoaded) {
      final currentState = state as MessageLoaded;
      emit(
        MessageLoaded(
          messages: List.from(cached.messages),
          actions: currentState.actions,
          isLoadingMore: currentState.isLoadingMore,
          isLoadingNewer: currentState.isLoadingNewer,
          hasMoreMessages: currentState.hasMoreMessages,
          hasNewerMessages: currentState.hasNewerMessages,
        ),
      );
    }

    // 4. Отправляем запрос на сервер
    final result = await _reactionsRepository.toggleReaction(
      chatId: event.chatId,
      entityId: event.entityId,
      entityType: event.entityType,
      messageId: event.messageId,
      nameReaction: event.nameReaction,
    );

    // 5. ОБРАБОТКА РЕЗУЛЬТАТА
    result.fold(
      (failure) {
        debugPrint(
          'Failed to toggle reaction: ${failure.message}. Rolling back...',
        );
        // 🎯 ОТКАТ: Возвращаем исходное сообщение, если запрос провалился
        cached.messages[msgIndex] = originalMsg;
        _messageRepository.cacheMessages(event.chatId, cached.messages);

        if (_chatRepository.isCurrentChat(event.chatId) &&
            state is MessageLoaded) {
          final currentState = state as MessageLoaded;
          emit(
            MessageLoaded(
              messages: List.from(cached.messages),
              actions: currentState.actions,
              isLoadingMore: currentState.isLoadingMore,
              isLoadingNewer: currentState.isLoadingNewer,
              hasMoreMessages: currentState.hasMoreMessages,
              hasNewerMessages: currentState.hasNewerMessages,
            ),
          );
        }
      },
      (_) {
        debugPrint('Reaction toggle request sent successfully.');
        // Успех! Когда придёт WebSocket, он просто подтвердит это состояние.
      },
    );
  }

  // Вынесенный вспомогательный метод для случая, когда кэша нет
  Future<void> _doApiToggle(ToggleReaction event) async {
    final result = await _reactionsRepository.toggleReaction(
      chatId: event.chatId,
      entityId: event.entityId,
      entityType: event.entityType,
      messageId: event.messageId,
      nameReaction: event.nameReaction,
    );
    result.fold(
      (failure) => debugPrint(
        'Failed to toggle reaction (no cache): ${failure.message}',
      ),
      (_) =>
          debugPrint('Reaction toggle request sent successfully (no cache).'),
    );
  }

  void _dispatchReactionEvent(WsEvent event, {required bool isCreate}) {
    final data = event.data;
    final messageId = data['messageId'] as int?;
    final chatId = data['chatId'] as int?;
    final nameReaction = data['nameReaction'] as String?;
    final amount = data['amount'] as int?;
    final hasUserReaction =
        event.isSelf && (data['hasUserReaction'] as bool? ?? false);
    final userId = data['userId'] as int?;

    if (messageId != null &&
        chatId != null &&
        nameReaction != null &&
        amount != null) {
      add(
        UpdateReactionFromWs(
          chatId: chatId,
          messageId: messageId,
          nameReaction: nameReaction,
          amount: amount,
          hasUserReaction: hasUserReaction,
          userId: userId,
        ),
      );
    }
  }

  Future<void> _onUpdateReactionFromWs(
    UpdateReactionFromWs event,
    Emitter<MessageState> emit,
  ) async {
    final cached = _messageRepository.getCached(event.chatId);
    if (cached == null) return;

    final msgIndex = cached.messages.indexWhere((m) => m.id == event.messageId);
    if (msgIndex == -1) return;

    final msg = cached.messages[msgIndex];
    final currentReactions = msg.reactions ?? [];
    final reactionIndex = currentReactions.indexWhere(
      (r) => r.nameReaction == event.nameReaction,
    );

    // 🎯 ПРОВЕРКА: Если состояние в кэше УЖЕ совпадает с тем, что пришло по WS,
    // мы ничего не делаем, чтобы избежать лишнего эмита.
    if (reactionIndex != -1) {
      final existing = currentReactions[reactionIndex];
      if (existing.amount == event.amount &&
          existing.hasUserReaction == event.hasUserReaction) {
        return; // Состояние уже актуально (скорее всего, благодаря оптимистичному обновлению)
      }
    } else if (!event.hasUserReaction && event.amount == 0) {
      // Реакции нет в кэше, и по WS пришло, что её тоже нет (amount 0, hasUserReaction false).
      // Состояние уже актуально.
      return;
    }

    // Если мы дошли сюда, значит состояние в кэше отличается от пришедшего по WS. Обновляем.
    List<ReactionMessage> newReactions = List.from(currentReactions);

    if (event.hasUserReaction) {
      if (reactionIndex != -1) {
        newReactions[reactionIndex] = newReactions[reactionIndex].copyWith(
          amount: event.amount,
          hasUserReaction: true,
        );
      } else {
        newReactions.add(
          ReactionMessage(
            messageId: event.messageId,
            userId: event.userId,
            nameReaction: event.nameReaction,
            amount: event.amount,
            hasUserReaction: true,
          ),
        );
      }
    } else {
      if (reactionIndex != -1) {
        if (event.amount == 0) {
          newReactions.removeAt(reactionIndex);
        } else {
          newReactions[reactionIndex] = newReactions[reactionIndex].copyWith(
            amount: event.amount,
            hasUserReaction: false,
          );
        }
      }
    }

    // Обновляем кэш
    cached.messages[msgIndex] = msg.copyWith(
      reactions: newReactions,
      clearReactions: newReactions.isEmpty,
    );
    _messageRepository.cacheMessages(event.chatId, cached.messages);

    // Эмитим состояние ТОЛЬКО если мы сейчас находимся в этом чате
    if (_chatRepository.isCurrentChat(event.chatId) && state is MessageLoaded) {
      final currentState = state as MessageLoaded;
      emit(
        MessageLoaded(
          messages: List.from(cached.messages),
          actions: currentState.actions,
          isLoadingMore: currentState.isLoadingMore,
          isLoadingNewer: currentState.isLoadingNewer,
          hasMoreMessages: currentState.hasMoreMessages,
          hasNewerMessages: currentState.hasNewerMessages,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    closeSubs();
    _messagesDuringLoad.clear();
    _actionsDuringLoad.clear();
    _messageRepository.clearAllCache();
    return super.close();
  }

  void closeSubs() {
    _createSubscription?.cancel();
    _updateSubscription?.cancel();
    _deleteSubscription?.cancel();
    _reactionCreateSubscription?.cancel();
    _reactionDeleteSubscription?.cancel();
    _historyCreateSubscription?.cancel();
    _historyUpdateSubscription?.cancel();
  }
}

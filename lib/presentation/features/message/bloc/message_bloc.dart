// lib/presentation/features/message/bloc/message_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/enums/file_content_type.dart';
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

      if (isAroundLoad) {
        final cachedResponse = _messageRepository.getCached(event.chatId);
        if (cachedResponse != null && cachedResponse.messages.isNotEmpty) {
          final aroundIndex = cachedResponse.messages.indexWhere(
            (m) => m.id == event.aroundId,
          );

          if (aroundIndex != -1) {
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
              finalMessages = serverMessages.length > event.limit
                  ? serverMessages.sublist(0, event.limit)
                  : serverMessages;
            }
          } else {
            finalMessages = serverMessages.length > event.limit
                ? serverMessages.sublist(0, event.limit)
                : serverMessages;
          }

          _messageRepository.cacheMessages(event.chatId, finalMessages);

          emit(
            MessageLoaded(
              messages: finalMessages,
              actions: response.actions,
              hasMoreMessages: isAroundLoad
                  ? true
                  : (finalMessages.length >= event.limit),
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
                  hasNewerMessages: currentState.hasNewerMessages,
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
            emit(
              MessageLoaded(
                messages: currentState.messages,
                actions: currentState.actions,
                isLoadingMore: false,
                isLoadingNewer: false,
                hasMoreMessages: currentState.hasMoreMessages,
                hasNewerMessages: false,
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
              hasNewerMessages: isNewerLoad
                  ? (serverMessages.length >= event.limit)
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
    if (cached == null) return;
    print(event.localGeneratedId);
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

  Future<void> _onToggleReaction(
    ToggleReaction event,
    Emitter<MessageState> emit,
  ) async {
    // Просто делаем запрос. UI обновится автоматически, когда придет WS-событие.
    final result = await _reactionsRepository.toggleReaction(
      chatId: event.chatId,
      entityId: event.entityId,
      entityType: event.entityType,
      messageId: event.messageId,
      reactionName: event.reactionName,
    );

    result.fold(
      (failure) {
        debugPrint('Failed to toggle reaction: ${failure.message}');
      },
      (_) {
        debugPrint(
          'Reaction toggle request sent successfully. Waiting for WS update.',
        );
      },
    );
  }

  void _dispatchReactionEvent(WsEvent event, {required bool isCreate}) {
    final data = event.data;
    final messageId = data['messageId'] as int?;
    final chatId = data['chatId'] as int?;
    final nameReaction = data['nameReaction'] as String?;
    final amount = data['amount'] as int?;
    final hasUserReaction = data['hasUserReaction'] as bool? ?? false;
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
    // 1. Проверяем, есть ли сообщение в кэше
    final cached = _messageRepository.getCached(event.chatId);
    if (cached == null) return;

    final msgIndex = cached.messages.indexWhere((m) => m.id == event.messageId);
    if (msgIndex == -1) return; // Сообщения нет в кэше, ничего не делаем

    final msg = cached.messages[msgIndex];
    final currentReactions = msg.reactions ?? [];
    final reactionIndex = currentReactions.indexWhere(
      (r) => r.nameReaction == event.nameReaction,
    );

    List<ReactionMessage> newReactions = List.from(currentReactions);

    // 2. Формируем новый список реакций
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

    // 3. Обновляем кэш (мутируем объект, как это делается в _onWsCreateEvent)
    cached.messages[msgIndex] = msg.copyWith(
      reactions: newReactions.isEmpty ? null : newReactions,
    );

    // Синхронизируем кэш в репозитории (на случай, если он ожидает явного вызова)
    _messageRepository.cacheMessages(event.chatId, cached.messages);

    // 4. Эмитим состояние ТОЛЬКО если мы сейчас находимся в этом чате
    if (_chatRepository.isCurrentChat(event.chatId) && state is MessageLoaded) {
      final currentState = state as MessageLoaded;
      emit(
        MessageLoaded(
          messages: cached.messages,
          // Передаем новый список, чтобы триггернуть перерисовку
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
    _messageRepository.clearAllCache();
    return super.close();
  }

  void closeSubs() {
    _createSubscription?.cancel();
    _updateSubscription?.cancel();
    _deleteSubscription?.cancel();
    _reactionCreateSubscription?.cancel();
    _reactionDeleteSubscription?.cancel();
  }
}

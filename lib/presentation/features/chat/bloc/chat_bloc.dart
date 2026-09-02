// lib/presentation/features/chat/bloc/chat_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/utils/chat_sorter.dart';
import 'package:flutter/cupertino.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final WsEventBus _eventBus;

  StreamSubscription<WsEvent>? _messageCreateSubscription;

  ChatBloc(this._chatRepository, this._eventBus) : super(ChatInitial()) {
    on<GetChats>(_onGetChats);
    on<AddMessageToChat>(_onAddMessageToChat);

    _setupWsListeners();
  }

  void _setupWsListeners() {
    print("SETUP WS LISTENERS");

    _messageCreateSubscription = _eventBus.subscribe(
      table: 'Message',
      action: ActionType.create,
      onData: (event) {
        final messageData = event.data['message'];
        if (messageData is Map<String, dynamic>) {
          final message = Message.fromMap(messageData);

          add(AddMessageToChat(message: message, isSelf: event.isSelf));
        }
      },
    );
  }

  Future<void> _onGetChats(GetChats event, Emitter<ChatState> emit) async {
    emit(ChatLoading());

    final cachedChats = _chatRepository.getCached();
    if (cachedChats.isNotEmpty) {
      emit(ChatLoaded(cachedChats));
    }

    final result = await _chatRepository.get();

    result.fold(
      (failure) {
        emit(ChatFailure(failure.message));
      },
      (chats) {
        emit(ChatLoaded(chats));
      },
    );
  }

  void _onAddMessageToChat(AddMessageToChat event, Emitter<ChatState> emit) {
    final message = event.message;
    final chatId = message.chatId ?? 0;

    if (chatId == 0) return;

    final cachedChats = _chatRepository.getCached();
    final chatIndex = cachedChats.indexWhere((c) => c.id == chatId);

    if (chatIndex != -1) {
      cachedChats[chatIndex] = cachedChats[chatIndex].copyWith(
        lastMessageTime: message.time,
      );

      if (!event.isSelf) {
        final currentCount = cachedChats[chatIndex].newMessagesCount ?? 0;
        cachedChats[chatIndex] = cachedChats[chatIndex].copyWith(
          newMessagesCount: currentCount + 1,
        );
      }

      // Сортируем чаты
      cachedChats.sort(ChatSorter.compare);

      emit(ChatLoaded(cachedChats));
    }
  }

  @override
  Future<void> close() {
    _messageCreateSubscription?.cancel();
    return super.close();
  }
}

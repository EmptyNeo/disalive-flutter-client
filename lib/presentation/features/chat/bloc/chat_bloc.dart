// lib/presentation/features/chat/bloc/chat_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/user.dart';
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
  StreamSubscription<WsEvent>? _userUpdateSubscription;
  StreamSubscription<WsEvent>? _chatCreateSubscription;
  StreamSubscription<WsEvent>? _chatUpdateSubscription;
  StreamSubscription<WsEvent>? _chatDeleteSubscription;

  ChatBloc(this._chatRepository, this._eventBus) : super(ChatInitial()) {
    on<GetChats>(_onGetChats);
    on<AddMessageToChat>(_onAddMessageToChat);
    on<SearchChats>(_onSearchChats);
    on<AddChat>(_onAddChat);
    on<UpdateChat>(_onUpdateChat);
    on<DeleteChat>(_onDeleteChat);
    on<UpdateUserInChat>(_onUpdateUserInChat);

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

    _userUpdateSubscription = _eventBus.subscribe(
      table: 'User',
      action: ActionType.update,
      onData: (event) {
        final userData = event.data['user'];
        if (userData is Map<String, dynamic>) {
          final user = UserModel.fromMap(userData);
          add(UpdateUserInChat(user));
        }
      },
    );

    // Новые подписки для чатов
    _chatCreateSubscription = _eventBus.subscribe(
      table: 'Chat',
      action: ActionType.create,
      onData: (event) {
        final chatData = event.data['chat'];
        if (chatData is Map<String, dynamic>) {
          final chat = Chat.fromMap(chatData);
          add(AddChat(chat));
        }
      },
    );

    _chatUpdateSubscription = _eventBus.subscribe(
      table: 'Chat',
      action: ActionType.update,
      onData: (event) {
        final chatData = event.data['chat'];
        if (chatData is Map<String, dynamic>) {
          final chat = Chat.fromMap(chatData);
          add(UpdateChat(chat));
        }
      },
    );

    _chatDeleteSubscription = _eventBus.subscribe(
      table: 'Chat',
      action: ActionType.delete,
      onData: (event) {
        final chatId = event.data['entityId'] ?? event.data['chatId'];
        if (chatId != null) {
          add(DeleteChat(int.tryParse(chatId.toString()) ?? 0));
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

  void _onAddChat(AddChat event, Emitter<ChatState> emit) {
    final cachedChats = _chatRepository.getCached();

    // Проверяем, нет ли уже такого чата
    final exists = cachedChats.any((c) => c.id == event.chat.id);
    if (exists) return;

    cachedChats.add(event.chat);
    cachedChats.sort(ChatSorter.compare);

    emit(ChatLoaded(cachedChats));
  }

  void _onUpdateChat(UpdateChat event, Emitter<ChatState> emit) {
    final cachedChats = _chatRepository.getCached();
    final index = cachedChats.indexWhere((c) => c.id == event.chat.id);

    if (index != -1) {
      final oldChat = cachedChats[index];
      final newChat = event.chat;

      // Обновляем только name и pathImage — то, что реально меняется
      cachedChats[index] = oldChat.copyWith(
        name: newChat.name,
        pathImage: newChat.pathImage ?? oldChat.pathImage,
      );

      // Сортируем (имя могло измениться)
      cachedChats.sort(ChatSorter.compare);

      emit(ChatLoaded(cachedChats));
    }
  }

  void _onDeleteChat(DeleteChat event, Emitter<ChatState> emit) {
    final cachedChats = _chatRepository.getCached();
    cachedChats.removeWhere((c) => c.id == event.chatId);

    emit(ChatLoaded(cachedChats));
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

  void _onUpdateUserInChat(UpdateUserInChat event, Emitter<ChatState> emit) {
    final cachedChats = _chatRepository.getCached();

    for (int i = 0; i < cachedChats.length; i++) {
      final chat = cachedChats[i];

      // Проверяем, является ли чат личным
      if (chat.isPersonalChat && chat.user?.id == event.user.id) {
        // Обновляем user в чате
        cachedChats[i] = chat.copyWith(
          user: event.user,
          name: event.user.displayName, // Обновляем имя чата
          pathImage: event.user.pathImage, // Обновляем аватар чата
        );
      }
    }

    // Сортируем (если нужно)
    cachedChats.sort(ChatSorter.compare);

    emit(ChatLoaded(cachedChats));
  }

  void _onSearchChats(SearchChats event, Emitter<ChatState> emit) {
    final query = event.query.trim().toLowerCase();

    if (query.isEmpty) {
      // Показываем все чаты
      final cachedChats = _chatRepository.getCached();
      emit(ChatLoaded(cachedChats));
      return;
    }

    final cachedChats = _chatRepository.getCached();
    final filteredChats = cachedChats
        .where((chat) => chat.name.toLowerCase().contains(query))
        .toList();

    emit(ChatLoaded(filteredChats));
  }

  @override
  Future<void> close() {
    _messageCreateSubscription?.cancel();
    _userUpdateSubscription?.cancel();
    _chatCreateSubscription?.cancel();
    _chatUpdateSubscription?.cancel();
    _chatDeleteSubscription?.cancel();
    return super.close();
  }
}

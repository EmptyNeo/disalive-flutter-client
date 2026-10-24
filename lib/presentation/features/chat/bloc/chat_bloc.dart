// lib/presentation/features/chat/bloc/chat_bloc.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:disalive/app/di/di.dart';
import 'package:bloc/bloc.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:disalive/presentation/utils/ui/chat_sorter.dart';
import 'package:flutter/cupertino.dart';

part 'chat_event.dart';

part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final WsEventBus _eventBus;

  StreamSubscription<WsEvent>? _messageCreateSubscription;
  StreamSubscription<WsEvent>? _messageUpdateSubscription;
  StreamSubscription<WsEvent>? _messageDeleteSubscription;
  StreamSubscription<WsEvent>? _memberUpdateSubscription;
  StreamSubscription<WsEvent>? _memberCreateSubscription;
  StreamSubscription<WsEvent>? _memberDeleteSubscription;
  StreamSubscription<WsEvent>? _userUpdateSubscription;
  StreamSubscription<WsEvent>? _chatCreateSubscription;
  StreamSubscription<WsEvent>? _chatUpdateSubscription;
  StreamSubscription<WsEvent>? _chatDeleteSubscription;
  StreamSubscription<WsEvent>? _chatUpdateBlockStatusSubscription;

  ChatBloc(this._chatRepository, this._eventBus) : super(ChatInitial()) {
    on<GetChats>(_onGetChats);
    on<AddMessageToChat>(_onAddMessageToChat);
    on<UpdateLastMessageInChat>(_onUpdateLastMessageInChat);
    on<RemoveMessageFromChat>(_onRemoveMessageFromChat);
    on<SearchChats>(_onSearchChats);
    on<AddChat>(_onAddChat);
    on<UpdateChat>(_onUpdateChat);
    on<DeleteChat>(_onDeleteChat);
    on<UpdateUserInChat>(_onUpdateUserInChat);
    on<UpdateMemberInChat>(_onUpdateMemberInChat);
    on<AddMembersToChat>(_onAddMembersToChat);
    on<RemoveMemberFromChat>(_onRemoveMemberFromChat);
  }

  void setupListeners() {
    closeSubs();
    print("SETUP WS LISTENERS");

    _messageCreateSubscription = _eventBus.subscribe(
      table: 'Message',
      action: ActionType.create,
      onData: (event) {
        final map = event.data['message'];
        if (map is Map<String, dynamic>) {
          final message = Message.fromMap(map);
          final hasPreview = event.data.containsKey('lastMessageText');
          add(
            AddMessageToChat(
              message: message,
              isSelf: event.isSelf,
              hasLastMessagePreview: hasPreview,
              lastMessageText: event.data['lastMessageText'] as String?,
              lastMessageUserId: DataParser.parseInt(
                event.data['lastMessageUserId'],
              ),
            ),
          );
        }
      },
    );

    _messageUpdateSubscription = _eventBus.subscribe(
      table: 'Message',
      action: ActionType.update,
      onData: (event) {
        if (!event.data.containsKey('lastMessageText')) return;
        final chatId = DataParser.parseInt(event.data['chatId']);
        if (chatId == null) return;
        add(
          UpdateLastMessageInChat(
            chatId: chatId,
            lastMessageText: event.data['lastMessageText'] as String?,
            lastMessageUserId: DataParser.parseInt(
              event.data['lastMessageUserId'],
            ),
          ),
        );
      },
    );

    _messageDeleteSubscription = _eventBus.subscribe(
      table: 'Message',
      action: ActionType.delete,
      onData: (event) {
        final chatId = DataParser.parseInt(event.data['chatId']);
        if (chatId == null) return;
        add(
          RemoveMessageFromChat(
            chatId: chatId,
            messageId: DataParser.parseInt(event.data['messageId']),
            messageUserId: DataParser.parseInt(event.data['messageUserId']),
            currentUserId: sl.isRegistered<UserRepository>()
                ? sl<UserRepository>().getCurrentUser()?.id
                : null,
            hasLastMessagePreview: event.data.containsKey('lastMessageText'),
            lastMessageText: event.data['lastMessageText'] as String?,
            lastMessageUserId: DataParser.parseInt(
              event.data['lastMessageUserId'],
            ),
            hasLastMessageId: event.data.containsKey('lastMessageId'),
            lastMessageId: DataParser.parseInt(event.data['lastMessageId']),
          ),
        );
      },
    );

    _memberUpdateSubscription = _eventBus.subscribe(
      table: 'ChatMembers',
      action: ActionType.update,
      onData: (event) {
        final map = event.data['member'];
        final chatId = event.data['chatId'];
        final userId = event.data['userId'];
        final isSelf = event.data['isSelf'];
        final entityType = EntityType.fromString(event.data['entityType']);
        if (map is Map<String, dynamic>) {
          final member = Member.fromMap(map);
          if (entityType == EntityType.chat) {
            add(
              UpdateMemberInChat(
                chatId: chatId,
                userId: userId,
                member: member,
                isSelf: isSelf,
              ),
            );
          }
        }
      },
    );

    _userUpdateSubscription = _eventBus.subscribe(
      table: 'User',
      action: ActionType.update,
      onData: (event) {
        final map = event.data['user'];
        if (map is Map<String, dynamic>) {
          final user = UserModel.fromMap(map);
          add(UpdateUserInChat(user, false));
        }
      },
    );

    // Новые подписки для чатов
    _chatCreateSubscription = _eventBus.subscribe(
      table: 'Chat',
      action: ActionType.create,
      onData: (event) {
        final map = event.data['chat'];
        if (map is Map<String, dynamic>) {
          final chat = Chat.fromMap(map);
          add(AddChat(chat));
        }
      },
    );

    _chatUpdateSubscription = _eventBus.subscribe(
      table: 'Chat',
      action: ActionType.update,
      onData: (event) {
        final map = event.data['chat'];
        if (map is Map<String, dynamic>) {
          final chat = Chat.fromMap(map);
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

    _chatUpdateBlockStatusSubscription = _eventBus.subscribe(
      table: 'Chat',
      action: ActionType.block,
      onData: (event) {
        final map = event.data['user'];
        if (map is Map<String, dynamic>) {
          final user = UserModel.fromMap(map);
          add(UpdateUserInChat(user, true));
        }
      },
    );

    _memberCreateSubscription = _eventBus.subscribe(
      table: 'ChatMembers',
      action: ActionType.create,
      onData: (event) {
        final entityId = DataParser.parseInt(event.data['entityId']);
        final entityTypeStr = event.data['entityType'];
        final memberCount = event.data['memberCount'] ?? 0;
        final membersData = event.data['members'];

        if (entityTypeStr == EntityType.chat.value && membersData is List) {
          final newMembers = membersData
              .map((m) => Member.fromMap(m as Map<String, dynamic>))
              .toList();

          add(
            AddMembersToChat(
              chatId: entityId,
              newMembers: newMembers,
              memberCount: memberCount,
            ),
          );
        }
      },
    );

    // 🎯 3. Подписка на УДАЛЕНИЕ участника (Remove/Leave)
    _memberDeleteSubscription = _eventBus.subscribe(
      table: 'ChatMembers',
      action: ActionType.delete,
      onData: (event) {
        final entityId = DataParser.parseInt(event.data['entityId']);
        final entityTypeStr = event.data['entityType'];
        final memberCount = event.data['memberCount'] ?? 0;
        final removedUserId = event.data['userId'];

        if (entityTypeStr == EntityType.chat.value && removedUserId != null) {
          add(
            RemoveMemberFromChat(
              chatId: entityId,
              removedUserId: removedUserId,
              memberCount: memberCount,
            ),
          );
        }
      },
    );
  }

  Future<void> _onGetChats(GetChats event, Emitter<ChatState> emit) async {
    emit(ChatLoading());

    final cachedChats = _chatRepository.getCached();
    if (cachedChats.isNotEmpty) {
      int unreadCount = _chatRepository.getAllUnredCount();
      emit(ChatLoaded(cachedChats, unreadCount));
      return;
    }

    final result = await _chatRepository.get();

    result.fold(
      (failure) {
        emit(ChatFailure(failure));
      },
      (chats) {
        int unreadCount = _chatRepository.getAllUnredCount();
        emit(ChatLoaded(chats, unreadCount));
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
    int unreadCount = _chatRepository.getAllUnredCount();

    emit(ChatLoaded(cachedChats, unreadCount));
  }

  void _onUpdateChat(UpdateChat event, Emitter<ChatState> emit) {
    final cachedChats = _chatRepository.getCached();
    final index = cachedChats.indexWhere((c) => c.id == event.chat.id);

    if (index != -1) {
      final oldChat = cachedChats[index];
      final newChat = event.chat;

      // Частичные обновления чата не должны сбрасывать последний текст.
      cachedChats[index] = oldChat.copyWith(
        name: newChat.name,
        pathImage: newChat.pathImage ?? oldChat.pathImage,
        lastMessageText: newChat.lastMessageText,
        lastMessageUserId: newChat.lastMessageUserId,
      );

      // Сортируем (имя могло измениться)
      cachedChats.sort(ChatSorter.compare);

      int unreadCount = _chatRepository.getAllUnredCount();

      emit(ChatLoaded(cachedChats, unreadCount));
    }
  }

  void _onDeleteChat(DeleteChat event, Emitter<ChatState> emit) {
    final cachedChats = _chatRepository.getCached();
    cachedChats.removeWhere((c) => c.id == event.chatId);
    int unreadCount = _chatRepository.getAllUnredCount();
    emit(ChatLoaded(cachedChats, unreadCount));
  }

  void _onAddMessageToChat(AddMessageToChat event, Emitter<ChatState> emit) {
    final message = event.message;
    final chatId = message.chatId ?? 0;

    if (chatId == 0) return;

    final cachedChats = _chatRepository.getCached();
    final chatIndex = cachedChats.indexWhere((c) => c.id == chatId);

    if (chatIndex != -1) {
      final chat = cachedChats[chatIndex];
      cachedChats[chatIndex] = chat.copyWith(
        lastMessageTime: message.time,
        lastMessageText: event.hasLastMessagePreview
            ? event.lastMessageText
            : message.text ?? '',
        clearLastMessageText:
            event.hasLastMessagePreview && event.lastMessageText == null,
        lastMessageUserId: event.hasLastMessagePreview
            ? event.lastMessageUserId
            : message.userId,
        clearLastMessageUserId:
            event.hasLastMessagePreview && event.lastMessageUserId == null,
        idLastMessage: message.id,
        newMessagesCount: chat.unreadCount + (event.isSelf ? 0 : 1),
      );

      // Сортируем чаты
      cachedChats.sort(ChatSorter.compare);
      int unreadCount = _chatRepository.getAllUnredCount();
      emit(ChatLoaded(cachedChats, unreadCount));
    }
  }

  void _onUpdateLastMessageInChat(
    UpdateLastMessageInChat event,
    Emitter<ChatState> emit,
  ) {
    final cachedChats = _chatRepository.getCached();
    final index = cachedChats.indexWhere((chat) => chat.id == event.chatId);
    if (index == -1) return;

    cachedChats[index] = cachedChats[index].copyWith(
      lastMessageText: event.lastMessageText,
      clearLastMessageText: event.lastMessageText == null,
      lastMessageUserId: event.lastMessageUserId,
      clearLastMessageUserId: event.lastMessageUserId == null,
      idLastMessage: event.lastMessageId,
      clearIdLastMessage: event.hasLastMessageId && event.lastMessageId == null,
    );
    emit(ChatLoaded(cachedChats, _chatRepository.getAllUnredCount()));
  }

  void _onRemoveMessageFromChat(
    RemoveMessageFromChat event,
    Emitter<ChatState> emit,
  ) {
    final chats = _chatRepository.getCached();
    final index = chats.indexWhere((chat) => chat.id == event.chatId);
    if (index == -1) return;
    final chat = chats[index];
    final isUnread =
        event.messageId != null &&
        event.messageUserId != null &&
        event.currentUserId != null &&
        event.messageUserId != event.currentUserId &&
        event.messageId! > (chat.member?.lastIdReadMessage ?? 0) &&
        chat.unreadCount > 0;
    chats[index] = chat.copyWith(
      newMessagesCount: isUnread ? math.max(0, chat.unreadCount - 1) : null,
      lastMessageText: event.hasLastMessagePreview
          ? event.lastMessageText
          : null,
      clearLastMessageText:
          event.hasLastMessagePreview && event.lastMessageText == null,
      lastMessageUserId: event.hasLastMessagePreview
          ? event.lastMessageUserId
          : null,
      clearLastMessageUserId:
          event.hasLastMessagePreview && event.lastMessageUserId == null,
      idLastMessage: event.lastMessageId,
      clearIdLastMessage: event.hasLastMessageId && event.lastMessageId == null,
    );
    emit(ChatLoaded(chats, _chatRepository.getAllUnredCount()));
  }

  void _onUpdateMemberInChat(
    UpdateMemberInChat event,
    Emitter<ChatState> emit,
  ) {
    final cachedChats = _chatRepository.getCached();
    final chatIndex = cachedChats.indexWhere((c) => c.id == event.chatId);

    if (chatIndex == -1) return;

    final chat = cachedChats[chatIndex];
    Chat updatedChat = chat;

    if (event.isSelf) {
      final unreadCount = math.max(
        0,
        (chat.idLastMessage ?? 0) - (event.member.lastIdReadMessage ?? 0),
      );
      final updatedCurrentMember = chat.member?.copyWith(
        muted: event.member.muted,
        fixed: event.member.fixed,
        orderFixed: event.member.orderFixed,
        lastIdReadMessage: event.member.lastIdReadMessage,
      );
      updatedChat = chat.copyWith(
        member: updatedCurrentMember,
        newMessagesCount: math.max(0, unreadCount),
      );
    } else {
      if (chat.members != null && chat.members!.isNotEmpty) {
        final memberIndex = chat.members!.indexWhere(
          (m) => m.fkUser == event.userId,
        );

        if (memberIndex != -1) {
          final updatedMembersList = List<Member>.from(chat.members!);

          updatedMembersList[memberIndex] = updatedMembersList[memberIndex]
              .copyWith(lastIdReadMessage: event.member.lastIdReadMessage);

          updatedChat = chat.copyWith(members: updatedMembersList);
        } else {
          final updatedMembersList = List<Member>.from(chat.members!);
          updatedMembersList.add(event.member);
          updatedChat = chat.copyWith(members: updatedMembersList);
        }
      }
    }

    if (updatedChat != chat) {
      cachedChats[chatIndex] = updatedChat;

      if (event.isSelf) {
        cachedChats.sort(ChatSorter.compare);
      }

      int unreadCount = _chatRepository.getAllUnredCount();
      emit(ChatLoaded(cachedChats, unreadCount));
      print(
        "✅ Chat members updated for chat ${event.chatId}, isSelf: ${event.isSelf}",
      );
    }
  }

  void _onUpdateUserInChat(UpdateUserInChat event, Emitter<ChatState> emit) {
    final cachedChats = _chatRepository.getCached();

    for (int i = 0; i < cachedChats.length; i++) {
      final chat = cachedChats[i];

      // Проверяем, является ли чат личным
      if (chat.isPersonalChat && chat.user?.id == event.user.id) {
        if (event.isUpdateBlock) {
          cachedChats[i] = chat.copyWith(
            user: chat.user?.copyWith(
              onlyIBlocked: event.user.onlyIBlocked,
              onlyTheyBlocked: event.user.onlyTheyBlocked,
              isAnyBlocked: event.user.isAnyBlocked,
              bothBlocked: event.user.bothBlocked,
            ),
            isBlocked: event.user.isAnyBlocked,
          );
        } else {
          // Обновляем user в чате
          cachedChats[i] = chat.copyWith(
            user: event.user,
            name: event.user.displayName, // Обновляем имя чата
            pathImage: event.user.pathImage, // Обновляем аватар чата
          );
        }
      }
    }

    // Сортируем (если нужно)
    cachedChats.sort(ChatSorter.compare);
    int unreadCount = _chatRepository.getAllUnredCount();
    emit(ChatLoaded(cachedChats, unreadCount));
  }

  void _onSearchChats(SearchChats event, Emitter<ChatState> emit) {
    final query = event.query.trim().toLowerCase();

    if (query.isEmpty) {
      // Показываем все чаты
      final cachedChats = _chatRepository.getCached();
      int unreadCount = _chatRepository.getAllUnredCount();
      emit(ChatLoaded(cachedChats, unreadCount));
      return;
    }

    final cachedChats = _chatRepository.getCached();
    final filteredChats = cachedChats
        .where((chat) => chat.name.toLowerCase().contains(query))
        .toList();
    int unreadCount = _chatRepository.getAllUnredCount();
    emit(ChatLoaded(filteredChats, unreadCount));
  }

  void _onAddMembersToChat(AddMembersToChat event, Emitter<ChatState> emit) {
    final cachedChats = _chatRepository.getCached();
    final chatIndex = cachedChats.indexWhere((c) => c.id == event.chatId);
    if (chatIndex == -1) return;

    final chat = cachedChats[chatIndex];
    final existingMembers = chat.members ?? [];

    // Безопасно объединяем списки, избегая дубликатов по fkUser
    final updatedMembersMap = {for (var m in existingMembers) m.fkUser: m};
    for (var m in event.newMembers) {
      updatedMembersMap[m.fkUser] = m;
    }

    final updatedChat = chat.copyWith(
      memberCount: event.memberCount,
      members: updatedMembersMap.values.toList(),
    );

    cachedChats[chatIndex] = updatedChat;
    emit(ChatLoaded(cachedChats, _chatRepository.getAllUnredCount()));
    print("✅ Added ${event.newMembers.length} members to chat ${event.chatId}");
  }

  void _onRemoveMemberFromChat(
    RemoveMemberFromChat event,
    Emitter<ChatState> emit,
  ) {
    final cachedChats = _chatRepository.getCached();
    final chatIndex = cachedChats.indexWhere((c) => c.id == event.chatId);
    if (chatIndex == -1) return;

    final chat = cachedChats[chatIndex];

    // Фильтруем список, удаляя пользователя с нужным ID
    final updatedMembers = chat.members
        ?.where((m) => m.fkUser != event.removedUserId)
        .toList();

    final updatedChat = chat.copyWith(
      memberCount: event.memberCount,
      members: updatedMembers,
    );

    cachedChats[chatIndex] = updatedChat;
    emit(ChatLoaded(cachedChats, _chatRepository.getAllUnredCount()));
    print("✅ Removed member $event.removedUserId from chat ${event.chatId}");
  }

  @override
  Future<void> close() {
    closeSubs();
    _chatRepository.clear();
    return super.close();
  }

  void closeSubs() {
    _messageCreateSubscription?.cancel();
    _messageUpdateSubscription?.cancel();
    _messageDeleteSubscription?.cancel();
    _memberUpdateSubscription?.cancel();
    _memberCreateSubscription?.cancel();
    _memberDeleteSubscription?.cancel();
    _userUpdateSubscription?.cancel();
    _chatCreateSubscription?.cancel();
    _chatUpdateSubscription?.cancel();
    _chatDeleteSubscription?.cancel();
    _chatUpdateBlockStatusSubscription?.cancel();
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/presentation/utils/ui/chat_sorter.dart';

class ChatRepositoryImpl implements ChatRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  List<Chat>? _chats;
  Chat? _currentChat;

  @override
  Future<Either<Failure, List<Chat>>> get() async {
    final result = await _httpClient.postFormData<List<Chat>>(
      endpoint: 'chats/get.php',
      data: null,
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is List) {
          return json
              .map((e) => Chat.fromMap(e as Map<String, dynamic>))
              .toList();
        }
        return <Chat>[];
      },
    );

    result.fold((failure) => null, (chats) {
      chats.sort(ChatSorter.compare);
      _chats = chats;
    });

    return result;
  }

  @override
  Future<Either<Failure, bool>> create(List<Chat> chats) async {
    final chatsJson = jsonEncode(chats.map((c) => c.toMap()).toList());

    final result = await _httpClient.postFormData<bool>(
      endpoint: 'chats/create.php',
      data: {'chats': chatsJson},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        return json is Map<String, dynamic>;
      },
    );

    return result;
  }

  @override
  Future<Either<Failure, bool>> update(
    int chatId,
    File? image,
    String name,
    bool deleted,
  ) async {
    final filesMap = image != null
        ? {
            'image': [image],
          }
        : <String, List<File?>>{};

    final result = await _httpClient.postMultipart<bool>(
      endpoint: 'chats/update.php',
      data: {'chatId': chatId, 'name': name, 'deleted': deleted},
      files: filesMap,
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        return json is Map<String, dynamic> && json['success'] == true;
      },
    );

    return result;
  }

  @override
  List<Chat> getCached() {
    return _chats ?? [];
  }

  @override
  void clear() {
    _chats = [];
  }

  @override
  Chat? getCurrentChat() {
    return _currentChat;
  }

  @override
  void setCurrentChat(Chat chat) {
    _currentChat = chat;
  }

  @override
  bool isCurrentChat(int chatId) {
    return _currentChat?.id == chatId;
  }

  @override
  int getAllUnredCount() {
    int unreadCount = 0;
    var chats = _chats;
    if (chats == null) {
      return 0;
    }

    if (chats.isEmpty) {
      return 0;
    }

    for (var chat in chats) {
      unreadCount += chat.unreadCount;
    }

    return unreadCount;
  }
}

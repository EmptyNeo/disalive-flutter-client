import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/chat.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<Chat>>> get();

  Future<Either<Failure, bool>> create(List<Chat> chats);

  Future<Either<Failure, bool>> update(
    int chatId,
    File? image,
    String name,
    bool deleted,
  );

  List<Chat> getCached();

  void clear();

  Chat? getCurrentChat();

  void setCurrentChat(Chat chat);

  bool isCurrentChat(int chatId);

  int getAllUnredCount();
}

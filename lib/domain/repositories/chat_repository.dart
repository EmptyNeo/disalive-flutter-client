import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/chat.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<Chat>>> get();

  Chat? _chat;

  List<Chat> getCached();

  Chat? getCurrentChat();

  void setCurrentChat(Chat chat);
}

// lib/domain/repositories/chat_server_repository.dart
import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';

abstract class ChatServerRepository {
  Future<Either<Failure, void>> connect(String token);

  void disconnect();

  void send(Map<String, dynamic> data);

  bool get isConnected;
}

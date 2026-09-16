// lib/domain/repositories/chat_server_repository.dart
import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/ui/ws_connection_status.dart';
import 'package:disalive/domain/failures/failures.dart';

abstract class ChatServerRepository {
  Future<Either<Failure, void>> connect();

  void disconnect();

  void send(Map<String, dynamic> data);

  bool get isConnected;

  Stream<WsConnectionStatus> get connectionStatusStream;
}

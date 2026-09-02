// lib/data/repositories/chat_server_repository_impl.dart
import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/chat_server_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatServerRepositoryImpl extends ChatServerRepository {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final WsEventBus _eventBus;

  ChatServerRepositoryImpl(this._eventBus);

  @override
  bool get isConnected => _channel != null;

  @override
  Future<Either<Failure, void>> connect(String token) async {
    try {
      const wsUrl = 'wss://disalive.ru:8081';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      await _channel!.ready;

      _channel!.sink.add(
        jsonEncode({
          'nameAction': 'Connect',
          'wsToken': token,
          'status': 'online',
        }),
      );

      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String);
            if (data is Map<String, dynamic>) {
              _processMessage(data);
            }
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          _channel = null;
          _subscription = null;
        },
      );

      return const Right(null);
    } catch (e) {
      _channel = null;
      return Left(ClientFailure(e.toString()));
    }
  }

  void _processMessage(Map<String, dynamic> data) {
    final table = data['table'] as String?;
    final actionStr = data['nameAction'] as String?;
    final action = ActionType.fromString(actionStr);

    if (table == null) {
      return;
    }

    _eventBus.dispatch(WsEvent(table: table, action: action, data: data));
  }

  @override
  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  @override
  void send(Map<String, dynamic> data) {
    if (_channel == null) {
      print('WebSocket is not connected');
      return;
    }

    _channel!.sink.add(jsonEncode(data));
  }

  void dispose() {
    disconnect();
  }
}

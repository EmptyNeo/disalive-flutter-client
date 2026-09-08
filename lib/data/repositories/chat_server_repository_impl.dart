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

  // Поля для авто-переподключения
  String? _currentToken;
  Timer? _reconnectTimer;
  int _retryAttempts = 0;
  bool _isManualDisconnect = false;

  ChatServerRepositoryImpl(this._eventBus);

  @override
  bool get isConnected => _channel != null;

  @override
  Future<Either<Failure, void>> connect(String token) async {
    _isManualDisconnect = false;
    _currentToken = token;
    _retryAttempts = 0;

    return _attemptConnection();
  }

  Future<Either<Failure, void>> _attemptConnection() async {
    // Отменяем предыдущий таймер переподключения, если он был
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      const wsUrl = 'wss://disalive.ru:8081';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      await _channel!.ready;

      _channel!.sink.add(
        jsonEncode({
          'nameAction': 'Connect',
          'wsToken': _currentToken,
          'status': 'online',
        }),
      );

      _setupStreamListener();
      return const Right(null);
    } catch (e) {
      _channel = null;
      _scheduleReconnect();
      return Left(ClientFailure(e.toString()));
    }
  }

  void _setupStreamListener() {
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
        _handleDisconnect();
      },
      onDone: () {
        print('WebSocket connection closed');
        _handleDisconnect();
      },
    );
  }

  void _handleDisconnect() {
    _channel = null;
    _subscription?.cancel();
    _subscription = null;

    // Если это не было вызвано методом disconnect(), пытаемся переподключиться
    if (!_isManualDisconnect && _currentToken != null) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isManualDisconnect) return;

    // Экспоненциальная задержка: 1с, 2с, 4с, 8с, 12с, максимум 12 секунд
    final delaySeconds = (1 << _retryAttempts).clamp(1, 12);
    _retryAttempts++;

    print('Scheduling WebSocket reconnect in $delaySeconds seconds...');

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      print('Attempting to reconnect WebSocket...');
      _attemptConnection();
    });
  }

  void _processMessage(Map<String, dynamic> data) {
    final table = data['table'] as String?;
    final actionStr = data['nameAction'] as String?;
    final isSelf = (data['isSelf'] ?? false) as bool;
    final action = ActionType.fromString(actionStr);

    if (table == null || action == null) return;

    _eventBus.dispatch(
      WsEvent(table: table, action: action, data: data, isSelf: isSelf),
    );
  }

  @override
  void disconnect() {
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _currentToken = null;
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

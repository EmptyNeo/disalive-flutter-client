// lib/data/repositories/chat_server_repository_impl.dart
import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/enums/ui/ws_connection_status.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';
import 'package:disalive/domain/repositories/chat_server_repository.dart';
import 'package:disalive/domain/repositories/ws_repository.dart';
import 'package:disalive/domain/services/ws_event_bus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatServerRepositoryImpl extends ChatServerRepository {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final WsEventBus _eventBus;
  final WsRepository _wsRepository;

  String? _currentToken;
  Timer? _reconnectTimer;
  int _retryAttempts = 0;
  bool _isManualDisconnect = false;

  final _statusController = StreamController<WsConnectionStatus>.broadcast();

  ChatServerRepositoryImpl(this._eventBus, this._wsRepository);

  @override
  bool get isConnected => _channel != null;

  @override
  Stream<WsConnectionStatus> get connectionStatusStream =>
      _statusController.stream;

  @override
  Future<Either<Failure, void>> connect() async {
    if (_channel != null) {
      return const Right(null);
    }

    _isManualDisconnect = false;
    _retryAttempts = 0;

    return _attemptConnection();
  }

  Future<Either<Failure, void>> _attemptConnection() async {
    _statusController.add(WsConnectionStatus.connecting);
    // Отменяем предыдущий таймер переподключения, если он был
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      final tokenResult = await _wsRepository.getToken();

      if (tokenResult.isLeft()) {
        final failure = tokenResult.fold((l) => l, (r) => null);
        print(
          '❌ Не удалось получить wsToken для подключения: ${failure?.message}',
        );
        _statusController.add(WsConnectionStatus.disconnected);
        _channel = null;
        _scheduleReconnect();
        return Left(failure!);
      }

      final freshToken = tokenResult.fold((l) => '', (r) => r);

      _currentToken = freshToken;

      const wsUrl = 'wss://disalive.ru:8081';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      await _channel!.ready;

      _channel!.sink.add(
        jsonEncode({
          'nameAction': 'Connect',
          'wsToken': freshToken,
          'status': 'online',
        }),
      );

      _setupStreamListener();

      _statusController.add(WsConnectionStatus.connected);
      return const Right(null);
    } catch (e) {
      _statusController.add(WsConnectionStatus.disconnected);
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
    _statusController.add(WsConnectionStatus.disconnected);
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
    _statusController.add(WsConnectionStatus.disconnected);
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
    _statusController.close();
    disconnect();
  }
}

// lib/domain/services/ws_event_bus.dart
import 'dart:async';

import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/models/ws/ws_event.dart';

/// Шина событий WebSocket для подписки на определенные таблицы и действия
class WsEventBus {
  final StreamController<WsEvent> _controller =
      StreamController<WsEvent>.broadcast();

  StreamSubscription<WsEvent> subscribe({
    required String table,
    required ActionType action,
    required void Function(Map<String, dynamic> data) onData,
  }) {
    return _controller.stream
        .where((event) => event.table == table && event.action == action)
        .listen((event) => onData(event.data));
  }

  StreamSubscription<WsEvent> subscribeToTable({
    required String table,
    required void Function(WsEvent event) onData,
  }) {
    return _controller.stream
        .where((event) => event.table == table)
        .listen(onData);
  }

  StreamSubscription<WsEvent> subscribeToAll({
    required void Function(WsEvent event) onData,
  }) {
    return _controller.stream.listen(onData);
  }

  void dispatch(WsEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

import 'package:disalive/domain/enums/action_type.dart';

class WsEvent {
  final String table;
  final ActionType action;
  final Map<String, dynamic> data;
  final bool isSelf;

  WsEvent({
    required this.table,
    required this.action,
    required this.data,
    required this.isSelf,
  });
}

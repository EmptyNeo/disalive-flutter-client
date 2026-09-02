// lib/domain/models/ui/message_grouped.dart
import 'package:disalive/domain/enums/ui/message_tail_direction.dart';
import 'package:disalive/domain/models/message.dart';

class MessageGrouped {
  final Message message;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool hasMessageAbove;
  final bool hasMessageBelow;
  final MessageTailDirection tailDirection;
  final bool showAvatar;
  final bool showTime;

  const MessageGrouped({
    required this.message,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.hasMessageAbove,
    required this.hasMessageBelow,
    required this.tailDirection,
    required this.showAvatar,
    required this.showTime,
  });
}
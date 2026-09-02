// lib/presentation/utils/message_grouper.dart
import 'package:disalive/domain/enums/ui/message_tail_direction.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ui/message_grouped.dart';
import 'package:disalive/presentation/utils/util_date.dart';

class MessageGrouper {
  MessageGrouper._();

  static List<MessageGrouped> group(
    List<Message> messages, {
    required bool isGroup,
    required int? currentUserId,
  }) {
    final grouped = <MessageGrouped>[];

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final nextMessage = i > 0 ? messages[i - 1] : null;
      final prevMessage = i < messages.length - 1 ? messages[i + 1] : null;
      final prevPrevMessage = prevMessage != null && i < messages.length - 2
          ? messages[i + 2]
          : null;

      final isMine = currentUserId != null && message.userId == currentUserId;
      final isOtherUserInGroup = isGroup && !isMine;

      final hasSameUserAbove = _isWithin5Minutes(message, prevMessage);
      final hasSameUserBelow = _isWithin5Minutes(message, nextMessage);

      MessageTailDirection tailDirection;
      bool showTime;
      bool showAvatarForGroup;

      if (isOtherUserInGroup) {
        // --- TELEGRAM-СТИЛЬ ДЛЯ ЧУЖИХ СООБЩЕНИЙ В ГРУППЕ ---
        if (!hasSameUserAbove && !hasSameUserBelow) {
          // 1. Единственное сообщение
          tailDirection = MessageTailDirection.down;
          showTime = true;
          showAvatarForGroup = true;
        } else if (!hasSameUserAbove && hasSameUserBelow) {
          // 2. Первое (самое верхнее/старое)
          tailDirection = MessageTailDirection.down;
          showTime = false;
          showAvatarForGroup = false;
        } else if (hasSameUserAbove && hasSameUserBelow) {
          // 3. Среднее сообщение
          tailDirection = MessageTailDirection.none;
          showTime = false;
          showAvatarForGroup = false;
        } else {
          // 4. Последнее (самое нижнее/новое)
          tailDirection = MessageTailDirection.down;
          showTime = true;
          showAvatarForGroup = true;
        }
      } else {
        // --- СТРОГАЯ ЛОГИКА ДЛЯ ЛИЧНЫХ ЧАТОВ И МОИХ СООБЩЕНИЙ ---
        if (!hasSameUserAbove && !hasSameUserBelow) {
          tailDirection = MessageTailDirection.up;
          showTime = true;
          showAvatarForGroup = false;
        } else if (!hasSameUserAbove && hasSameUserBelow) {
          tailDirection = MessageTailDirection.down;
          showTime = true;
          showAvatarForGroup = false;
        } else if (hasSameUserAbove && hasSameUserBelow) {
          tailDirection = MessageTailDirection.none;
          showTime = false;
          showAvatarForGroup = false;
        } else {
          tailDirection = MessageTailDirection.up;
          final bool hasSomeoneAbovePrev = _isWithin5Minutes(
            prevMessage,
            prevPrevMessage,
          );
          showTime = !hasSomeoneAbovePrev;
          showAvatarForGroup = false;
        }
      }

      grouped.add(
        MessageGrouped(
          message: message,
          isFirstInGroup: !hasSameUserAbove,
          isLastInGroup: !hasSameUserBelow,
          hasMessageAbove: hasSameUserAbove,
          hasMessageBelow: hasSameUserBelow,
          tailDirection: tailDirection,
          showAvatar: showAvatarForGroup,
          showTime: showTime,
        ),
      );
    }

    return grouped;
  }

  static bool _isWithin5Minutes(Message? m1, Message? m2) {
    if (m1 == null || m2 == null) return false;
    if (m1.userId != m2.userId) return false;
    final t1 = UtilDate.parseDateTime(m1.time);
    final t2 = UtilDate.parseDateTime(m2.time);
    if (t1 == null || t2 == null) return false;
    return t1.difference(t2).abs() <= const Duration(minutes: 5);
  }
}

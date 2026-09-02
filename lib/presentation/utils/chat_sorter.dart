// lib/presentation/utils/chat_sorter.dart
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/presentation/utils/util_date.dart';

class ChatSorter {
  ChatSorter._();

  static int compare(Chat a, Chat b) {
    final bool aPinned = a.member?.isFixed ?? false;
    final bool bPinned = b.member?.isFixed ?? false;

    if (aPinned != bPinned) {
      return aPinned ? -1 : 1;
    }

    if (aPinned && bPinned) {
      final int? aOrder = a.member?.orderFixed;
      final int? bOrder = b.member?.orderFixed;
      if (aOrder != null && bOrder != null && aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      if (aOrder != null && bOrder == null) return -1;
      if (aOrder == null && bOrder != null) return 1;
    }

    final aTime = UtilDate.parseDateTime(a.lastMessageTime);
    final bTime = UtilDate.parseDateTime(b.lastMessageTime);
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return bTime.compareTo(aTime);
  }
}
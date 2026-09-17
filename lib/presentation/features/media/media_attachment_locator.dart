import 'package:disalive/domain/enums/ui/media_step_direction.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/models/ui/media_position.dart';

class MediaAttachmentLocator {
  const MediaAttachmentLocator._();

  static List<FileMessage> _getAttachments(Message m) {
    final contentMessage = m.forwardMessage ?? m;
    return contentMessage.attachments
        ?.where((a) => a.isImageFile || a.isVideoFile)
        .toList() ??
        const [];
  }

  static MediaPosition? step(
      List<Message> messages,
      MediaPosition from,
      MediaStepDirection direction,
      ) {
    if (messages.isEmpty) return null;

    final currentIndex = messages.indexWhere(
          (m) => (m.id ?? m.localGeneratedId) == from.messageId,
    );
    if (currentIndex == -1) return null;

    final currentAttachments = _getAttachments(messages[currentIndex]);

    if (direction == MediaStepDirection.newer) {
      // 🎯 Двигаемся "вперёд" по галерее (к более новым медиа).
      // Сначала пытаемся взять следующее вложение в ЭТОМ ЖЕ сообщении.
      if (from.attachmentIndex + 1 < currentAttachments.length) {
        return MediaPosition(
          messageId: from.messageId,
          attachmentIndex: from.attachmentIndex + 1,
        );
      }

      // Вложения в этом сообщении закончились. Ищем следующее (более новое) сообщение.
      // В списке чата новые сообщения имеют меньший индекс (ближе к 0).
      for (int i = currentIndex - 1; i >= 0; i--) {
        final nextAttachments = _getAttachments(messages[i]);
        if (nextAttachments.isNotEmpty) {
          return MediaPosition(
            messageId: messages[i].id,
            attachmentIndex: 0, // Начинаем с первого вложения нового сообщения
          );
        }
      }
      return null; // Новых сообщений с медиа нет
    } else {
      // 🎯 direction == MediaStepDirection.older
      // Двигаемся "назад" по галерее (к более старым медиа).
      // Сначала пытаемся взять предыдущее вложение в ЭТОМ ЖЕ сообщении.
      if (from.attachmentIndex - 1 >= 0) {
        return MediaPosition(
          messageId: from.messageId,
          attachmentIndex: from.attachmentIndex - 1,
        );
      }

      // Это было первое вложение. Ищем предыдущее (более старое) сообщение.
      // В списке чата старые сообщения имеют больший индекс.
      for (int i = currentIndex + 1; i < messages.length; i++) {
        final prevAttachments = _getAttachments(messages[i]);
        if (prevAttachments.isNotEmpty) {
          return MediaPosition(
            messageId: messages[i].id,
            attachmentIndex: prevAttachments.length - 1, // Начинаем с последнего вложения старого сообщения
          );
        }
      }
      return null; // Старых сообщений с медиа нет
    }
  }
}
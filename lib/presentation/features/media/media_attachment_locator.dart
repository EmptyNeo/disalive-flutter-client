// presentation/features/media/media_attachment_locator.dart
import 'package:disalive/domain/enums/ui/media_step_direction.dart';
import 'package:disalive/domain/models/message.dart';

/// Координата конкретного вложения: индекс сообщения в том же списке
/// [Message], которым уже пользуется MessageBloc/MessagesList, и индекс
/// вложения внутри message.attachments.
class MediaPosition {
  const MediaPosition({
    required this.messageId, // <-- Заменили messageIndex на messageId
    required this.attachmentIndex,
  });

  final int? messageId; // Может быть null для локальных сообщений
  final int attachmentIndex;

  @override
  bool operator ==(Object other) =>
      other is MediaPosition &&
      other.messageId == messageId &&
      other.attachmentIndex == attachmentIndex;

  @override
  int get hashCode => Object.hash(messageId, attachmentIndex);
}

/// Находит соседнее вложение при свайпе, перетекая из одного сообщения в
/// другое, когда вложения текущего сообщения заканчиваются.
///
/// Пагинацию НЕ трогает — если шаг в сторону старых сообщений упирается в
/// конец уже загруженного списка, просто возвращает null; решение "нужно ли
/// догрузить ещё" остаётся за вызывающей стороной (у неё есть
/// hasMoreMessages из MessageBloc).
class MediaAttachmentLocator {
  const MediaAttachmentLocator._();

  static MediaPosition? step(
    List<Message> messages,
    MediaPosition from,
    MediaStepDirection direction,
  ) {
    if (messages.isEmpty) return null;

    // Находим текущий индекс по ID
    final currentIndex = messages.indexWhere((m) => m.id == from.messageId);
    if (currentIndex == -1) return null;

    final delta = direction == MediaStepDirection.older ? 1 : -1;

    final current =
        messages[currentIndex].attachments
            ?.where((a) => a.isImageFile || a.isVideoFile)
            .toList() ??
        const [];

    final withinMessage = from.attachmentIndex + delta;
    if (withinMessage >= 0 && withinMessage < current.length) {
      return MediaPosition(
        messageId: from.messageId,
        attachmentIndex: withinMessage,
      );
    }

    var searchIndex = currentIndex + delta;
    while (searchIndex >= 0 && searchIndex < messages.length) {
      final attachments =
          messages[searchIndex].attachments
              ?.where((a) => a.isImageFile || a.isVideoFile)
              .toList() ??
          const [];

      if (attachments.isNotEmpty) {
        final landingIndex = delta > 0 ? 0 : attachments.length - 1;
        return MediaPosition(
          messageId: messages[searchIndex].id, // Возвращаем ID, а не индекс
          attachmentIndex: landingIndex,
        );
      }
      searchIndex += delta;
    }

    return null;
  }
}

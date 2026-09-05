// presentation/features/media/media_attachment_locator.dart
import 'package:disalive/domain/enums/ui/media_step_direction.dart';
import 'package:disalive/domain/models/message.dart';

/// Координата конкретного вложения: индекс сообщения в том же списке
/// [Message], которым уже пользуется MessageBloc/MessagesList, и индекс
/// вложения внутри message.attachments.
class MediaPosition {
  const MediaPosition({
    required this.messageIndex,
    required this.attachmentIndex,
  });

  final int messageIndex;
  final int attachmentIndex;

  @override
  bool operator ==(Object other) =>
      other is MediaPosition &&
      other.messageIndex == messageIndex &&
      other.attachmentIndex == attachmentIndex;

  @override
  int get hashCode => Object.hash(messageIndex, attachmentIndex);
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
    if (messages.isEmpty || from.messageIndex >= messages.length) return null;

    final delta = direction == MediaStepDirection.older ? 1 : -1;

    // Фильтруем только изображения и видео
    final current =
        messages[from.messageIndex].attachments
            ?.where((a) => a.isImageFile || a.isVideoFile)
            .toList() ??
        const [];

    final withinMessage = from.attachmentIndex + delta;
    if (withinMessage >= 0 && withinMessage < current.length) {
      return MediaPosition(
        messageIndex: from.messageIndex,
        attachmentIndex: withinMessage,
      );
    }

    var messageIndex = from.messageIndex + delta;
    while (messageIndex >= 0 && messageIndex < messages.length) {
      final attachments =
          messages[messageIndex].attachments
              ?.where((a) => a.isImageFile || a.isVideoFile)
              .toList() ??
          const [];

      if (attachments.isNotEmpty) {
        final landingIndex = delta > 0 ? 0 : attachments.length - 1;
        return MediaPosition(
          messageIndex: messageIndex,
          attachmentIndex: landingIndex,
        );
      }
      messageIndex += delta;
    }

    return null;
  }
}

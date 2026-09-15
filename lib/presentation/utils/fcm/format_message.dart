import 'package:disalive/domain/models/message.dart';

class FormatMessage {
  static String getBody(Message message) {
    final hasText = message.text != null && message.text!.isNotEmpty;
    final hasAttachments = message.attachments?.isNotEmpty ?? false;

    if (!hasText && !hasAttachments) {
      return 'Новое сообщение';
    }

    String textPart = hasText ? message.text! : '';

    String attachmentsPart = '';
    if (hasAttachments) {
      final attachments = message.attachments;
      final count = attachments?.length;
      final first = attachments?.first;
      if (first != null) {
        if (count == 1) {
          if (first.isAudioFile) {
            attachmentsPart = 'Голосовое сообщение';
          } else if (first.isImageFile) {
            attachmentsPart = 'Фото';
          } else if (first.isVideoFile) {
            attachmentsPart = 'Видео';
          } else if (first.isOtherFile) {
            attachmentsPart = 'Файл';
          }
        } else {
          if (first.isImageFile) {
            attachmentsPart = '$count фото';
          } else if (first.isVideoFile) {
            attachmentsPart = '$count видео';
          } else if (first.isOtherFile) {
            attachmentsPart = '$count вложений';
          }
        }
      }
    }

    if (hasText && hasAttachments) {
      return '$textPart ($attachmentsPart)';
    } else if (hasText) {
      return textPart;
    } else {
      return attachmentsPart;
    }
  }
}

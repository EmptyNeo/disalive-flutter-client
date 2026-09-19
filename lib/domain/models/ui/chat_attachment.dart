// lib/presentation/features/chat/models/chat_attachment.dart
import 'dart:io';

import 'package:disalive/domain/enums/file_content_type.dart';
import 'package:disalive/domain/enums/file_type.dart';
import 'package:disalive/domain/models/file_message.dart';

class ChatAttachment {
  final int? id; // null, если это новый файл
  final File? file; // null, если это существующий файл из редактирования
  final String? url;
  final String name;
  final double size; // в байтах
  final String unit; // 'Б', 'КБ', 'МБ', 'ГБ'
  final FileType fileType;
  final FileContentType contentType;
  final double? duration;

  bool isSpoiler;
  bool isDeleted;

  ChatAttachment({
    this.id,
    this.file,
    this.url,
    required this.name,
    required this.size,
    required this.unit,
    required this.fileType,
    required this.contentType,
    this.duration,
    this.isSpoiler = false,
    this.isDeleted = false,
  });

  FileMessage toFileMessage(int index) {
    return FileMessage(
      id: -1 - index,
      messageId: null,
      pathFile: file?.path ?? '',
      originalName: name,
      size: size,
      unit: unit,
      fileType: fileType,
      duration: duration,
      isSpoiler: isSpoiler ? 1 : 0,
    );
  }

  bool get isNew => id == null;

  bool get isChanged => isSpoiler || isDeleted;

  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}

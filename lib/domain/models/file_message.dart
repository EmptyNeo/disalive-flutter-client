// lib/domain/models/file_message.dart
import 'package:equatable/equatable.dart';
import 'package:disalive/domain/enums/file_content_type.dart';
import 'package:disalive/domain/enums/file_type.dart';

class FileMessage extends Equatable {
  final int? id;
  final int? messageId;
  final int? packId;
  final String? pathFile;
  final String? originalName;
  final double? size;
  final String? unit;
  final FileContentType contentType;
  final String? objectKey;
  final int? isSpoiler;
  final String? mimeType;
  final FileType fileType;

  const FileMessage({
    this.id,
    this.messageId,
    this.packId,
    this.pathFile,
    this.originalName,
    this.size,
    this.unit,
    this.contentType = FileContentType.defaultFile,
    this.objectKey,
    this.isSpoiler,
    this.mimeType,
    this.fileType = FileType.file,
  });

  factory FileMessage.fromMap(Map<String, dynamic> map) {
    final originalName = map['originalName'] as String?;
    final mimeType = map['mimeType'] as String?;
    final extension = _getExtension(originalName);

    return FileMessage(
      id: map['id'],
      messageId: map['fkMessage'],
      packId: map['idPack'],
      pathFile: map['pathFile'],
      originalName: originalName,
      size: (map['size'] as num?)?.toDouble(),
      unit: map['unit'],
      contentType: FileContentType.fromString(map['type']),
      objectKey: map['objectKey'],
      isSpoiler: map['isSpoiler'],
      mimeType: mimeType,
      fileType: mimeType != null && mimeType.isNotEmpty
          ? FileType.fromMimeType(mimeType)
          : FileType.fromExtension(extension),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (messageId != null) 'messageId': messageId,
      if (packId != null) 'idPack': packId,
      if (pathFile != null) 'pathFile': pathFile,
      if (originalName != null) 'originalName': originalName,
      if (size != null) 'size': size,
      if (unit != null) 'unit': unit,
      if (contentType != FileContentType.defaultFile) 'type': contentType.value,
      if (objectKey != null) 'objectKey': objectKey,
      if (isSpoiler != null) 'isSpoiler': isSpoiler,
      if (mimeType != null) 'mimeType': mimeType,
    };
  }

  FileMessage copyWith({
    int? id,
    int? messageId,
    int? packId,
    String? pathFile,
    String? originalName,
    double? size,
    String? unit,
    FileContentType? contentType,
    String? objectKey,
    int? isSpoiler,
    String? mimeType,
    FileType? fileType,
  }) {
    return FileMessage(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      packId: packId ?? this.packId,
      pathFile: pathFile ?? this.pathFile,
      originalName: originalName ?? this.originalName,
      size: size ?? this.size,
      unit: unit ?? this.unit,
      contentType: contentType ?? this.contentType,
      objectKey: objectKey ?? this.objectKey,
      isSpoiler: isSpoiler ?? this.isSpoiler,
      mimeType: mimeType ?? this.mimeType,
      fileType: fileType ?? this.fileType,
    );
  }

  static String? _getExtension(String? fileName) {
    if (fileName == null || fileName.isEmpty) return null;
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot >= 0) {
      return fileName.substring(lastDot + 1);
    }
    return null;
  }

  // Геттеры
  bool get isSpoilerFile => isSpoiler == 1;

  bool get isDefaultFile => contentType == FileContentType.defaultFile;

  bool get isSticker => contentType == FileContentType.sticker;

  bool get isGif => contentType == FileContentType.gif;

  bool get hasValidPath => pathFile != null && pathFile!.isNotEmpty;

  bool get isImageFile => fileType == FileType.image;

  bool get isVideoFile => fileType == FileType.video;

  bool get isAudioFile => fileType == FileType.audio;

  bool get isOtherFile => fileType == FileType.file;

  String get formattedSize {
    if (size == null) return '';
    return '${_formatSize(size!)} ${unit ?? 'B'}';
  }

  String _formatSize(double size) {
    if (size >= 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (size >= 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (size >= 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${size.toStringAsFixed(0)} B';
    }
  }

  String get extension {
    return _getExtension(originalName) ?? '';
  }

  @override
  List<Object?> get props => [
    id,
    messageId,
    packId,
    pathFile,
    originalName,
    size,
    unit,
    contentType,
    objectKey,
    isSpoiler,
    mimeType,
    fileType,
  ];
}

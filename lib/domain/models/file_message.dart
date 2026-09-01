// lib/domain/models/file_message.dart
import 'package:equatable/equatable.dart';

class FileMessage extends Equatable {
  final int? id;
  final int? messageId;
  final int? packId;
  final String? pathFile;
  final String? originalName;
  final double? size;
  final String? unit;
  final String? type;
  final String? objectKey;
  final int? isSpoiler;

  // Дополнительные поля
  final String? mimeType;

  const FileMessage({
    this.id,
    this.messageId,
    this.packId,
    this.pathFile,
    this.originalName,
    this.size,
    this.unit,
    this.type,
    this.objectKey,
    this.isSpoiler,
    this.mimeType,
  });

  factory FileMessage.fromMap(Map<String, dynamic> map) {
    return FileMessage(
      id: map['id'],
      messageId: map['fkMessage'],
      packId: map['idPack'],
      pathFile: map['pathFile'],
      originalName: map['originalName'],
      size: (map['size'] as num?)?.toDouble(),
      unit: map['unit'],
      type: map['type'] ?? 'defaultFile',
      objectKey: map['objectKey'],
      isSpoiler: map['isSpoiler'],
      mimeType: map['mimeType'],
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
      if (type != null) 'type': type,
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
    String? type,
    String? objectKey,
    int? isSpoiler,
    String? mimeType,
  }) {
    return FileMessage(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      packId: packId ?? this.packId,
      pathFile: pathFile ?? this.pathFile,
      originalName: originalName ?? this.originalName,
      size: size ?? this.size,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      objectKey: objectKey ?? this.objectKey,
      isSpoiler: isSpoiler ?? this.isSpoiler,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  // Геттеры
  bool get isSpoilerFile => isSpoiler == 1;

  bool get isDefaultFile => type == 'defaultFile';

  bool get hasValidPath => pathFile != null && pathFile!.isNotEmpty;

  // Форматированный размер
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
    if (originalName == null || originalName!.isEmpty) return '';
    final lastDot = originalName!.lastIndexOf('.');
    return lastDot >= 0
        ? originalName!.substring(lastDot + 1).toLowerCase()
        : '';
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
    type,
    objectKey,
    isSpoiler,
    mimeType,
  ];
}

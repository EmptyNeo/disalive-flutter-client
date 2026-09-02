// lib/domain/enums/file_type.dart
enum FileType {
  image('image'),
  video('video'),
  audio('audio'),
  file('file');

  final String value;

  const FileType(this.value);

  /// Определить тип файла по расширению
  static FileType fromExtension(String? extension) {
    if (extension == null || extension.isEmpty) return FileType.file;

    final ext = extension.toLowerCase().replaceAll('.', '');

    // Изображения
    const imageExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'svg',
      'ico',
      'tiff',
      'psd',
      'heic',
      'heif',
      'avif',
      'jp2',
      'jpx',
      'jpm',
      'wbmp',
    ];

    // Видео
    const videoExtensions = [
      'mp4',
      'mpeg',
      'mpg',
      'ogv',
      'webm',
      'mov',
      'avi',
      'flv',
      'wmv',
      'mkv',
      'm4v',
      '3gp',
      '3g2',
      'ts',
      'vob',
      'asf',
      'divx',
      'f4v',
    ];

    // Аудио
    const audioExtensions = [
      'mp3',
      'wav',
      'ogg',
      'aac',
      'flac',
      'm4a',
      'wma',
      'mid',
      'opus',
      'amr',
      'au',
      'ra',
      'ac3',
      'eac3',
      'mka',
      'weba',
    ];

    if (imageExtensions.contains(ext)) return FileType.image;
    if (videoExtensions.contains(ext)) return FileType.video;
    if (audioExtensions.contains(ext)) return FileType.audio;

    return FileType.file;
  }

  /// Определить тип файла по MIME типу
  static FileType fromMimeType(String? mimeType) {
    if (mimeType == null || mimeType.isEmpty) return FileType.file;

    final mime = mimeType.toLowerCase();

    if (mime.startsWith('image/')) return FileType.image;
    if (mime.startsWith('video/')) return FileType.video;
    if (mime.startsWith('audio/')) return FileType.audio;

    return FileType.file;
  }

  bool get isImage => this == FileType.image;

  bool get isVideo => this == FileType.video;

  bool get isAudio => this == FileType.audio;

  bool get isFile => this == FileType.file;
}

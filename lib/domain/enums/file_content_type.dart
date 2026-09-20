// lib/domain/enums/file_content_type.dart
enum FileContentType {
  defaultFile('defaultFile'),
  sticker('sticker'),
  gif('gif'),
  voice('voice');

  final String value;

  const FileContentType(this.value);

  static FileContentType fromString(String? value) {
    if (value == null) return FileContentType.defaultFile;
    for (final type in FileContentType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return FileContentType.defaultFile;
  }

  bool get isSticker => this == FileContentType.sticker;

  bool get isGif => this == FileContentType.gif;

  bool get isDefaultFile => this == FileContentType.defaultFile;

  bool get isVoice => this == FileContentType.voice;
}

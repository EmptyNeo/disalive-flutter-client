import 'package:disalive/domain/enums/file_content_type.dart';

class SymbolData {
  final String? filePath;
  final FileContentType? typeFile;
  final int? packId;

  const SymbolData({this.filePath, this.typeFile, this.packId});
}

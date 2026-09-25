import 'package:disalive/data/network/domain.dart';

class StickerContent {
  final int id;
  final String pathFile;
  final int packId;

  const StickerContent({
    required this.id,
    required this.pathFile,
    required this.packId,
  });

  factory StickerContent.fromMap(Map<String, dynamic> map) {
    return StickerContent(
      id: map['idSticker'],
      pathFile: map['pathFile'],
      packId: map['packId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {"id": id, "pathFile": pathFile, "packId": packId};
  }

  String get urlPath => Domain.transformUrl(pathFile);
}

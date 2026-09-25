import 'package:disalive/domain/models/sticker_content.dart';
import 'package:equatable/equatable.dart';

class StickerPack extends Equatable {
  final int id;
  final String name;
  final bool isCreator;
  final List<StickerContent>? attachments;
  final bool hasPack;

  const StickerPack({
    required this.id,
    required this.name,
    required this.isCreator,
    required this.attachments,
    required this.hasPack,
  });

  factory StickerPack.fromMap(Map<String, dynamic> map) {
    return StickerPack(
      id: map['idPack'],
      name: map['packName'],
      isCreator: map['isCreator'],
      attachments: map['attachments'] != null
          ? (map['attachments'] as List)
                .map((e) => StickerContent.fromMap(e as Map<String, dynamic>))
                .toList()
          : null,
      hasPack: map['hasPack'],
    );
  }

  @override
  List<Object?> get props => [id, name, isCreator, hasPack, attachments];
}

import 'package:disalive/presentation/utils/data_parser.dart';
import 'package:equatable/equatable.dart';

/// Один элемент результата раздела «Медиа и файлы».
sealed class MediaFilterItem extends Equatable {
  const MediaFilterItem();
}

/// Вложения и ссылки можно связать с исходным сообщением.
sealed class MediaFilterMessageItem extends MediaFilterItem {
  const MediaFilterMessageItem({required this.idMessage});

  final int idMessage;
}

/// Фото, видео, документ и аудиофайл имеют одинаковый формат ответа API.
final class MediaFilterFile extends MediaFilterMessageItem {
  const MediaFilterFile({
    required this.idFilesMessage,
    required this.pathFile,
    required super.idMessage,
    this.originalName,
    this.size,
    this.unit,
    this.objectKey,
    this.thumbnailUrl,
  });

  final int idFilesMessage;
  final String pathFile;
  final String? originalName;
  final double? size;
  final String? unit;
  final String? objectKey;
  final String? thumbnailUrl;

  factory MediaFilterFile.fromMap(Map<String, dynamic> map) => MediaFilterFile(
    idFilesMessage: _requiredInt(map, 'idFilesMessage'),
    pathFile: map['pathFile'] as String,
    idMessage: _requiredInt(map, 'idMessage'),
    originalName: map['originalName'] as String?,
    size: _optionalDouble(map['size']),
    unit: map['unit'] as String?,
    objectKey: map['objectKey'] as String?,
    thumbnailUrl: map['thumbnailUrl'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'idFilesMessage': idFilesMessage,
    'pathFile': pathFile,
    if (originalName != null) 'originalName': originalName,
    if (size != null) 'size': size,
    if (unit != null) 'unit': unit,
    if (objectKey != null) 'objectKey': objectKey,
    'idMessage': idMessage,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
  };

  @override
  List<Object?> get props => [
    idFilesMessage,
    pathFile,
    originalName,
    size,
    unit,
    objectKey,
    idMessage,
    thumbnailUrl,
  ];
}

final class MediaFilterLink extends MediaFilterMessageItem {
  const MediaFilterLink({
    required this.link,
    required super.idMessage,
    required this.time,
    required this.fkSender,
    required this.domain,
    this.title,
    this.description,
    this.image,
  });

  final String link;
  final String time;
  final int fkSender;
  final String domain;
  final String? title;
  final String? description;
  final String? image;

  factory MediaFilterLink.fromMap(Map<String, dynamic> map) => MediaFilterLink(
    link: map['link'] as String,
    idMessage: _requiredInt(map, 'idMessage'),
    time: map['time'] as String,
    fkSender: _requiredInt(map, 'fkSender'),
    domain: map['domain'] as String,
    title: map['title'] as String?,
    description: map['description'] as String?,
    image: map['image'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'link': link,
    'idMessage': idMessage,
    'time': time,
    'fkSender': fkSender,
    'domain': domain,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (image != null) 'image': image,
  };

  @override
  List<Object?> get props => [
    link,
    idMessage,
    time,
    fkSender,
    domain,
    title,
    description,
    image,
  ];
}

final class MediaFilterMutualGroup extends MediaFilterItem {
  const MediaFilterMutualGroup({
    required this.idChat,
    required this.name,
    required this.memberCount,
    this.pathImage,
  });

  final int idChat;
  final String name;
  final String? pathImage;
  final int memberCount;

  factory MediaFilterMutualGroup.fromMap(Map<String, dynamic> map) =>
      MediaFilterMutualGroup(
        idChat: _requiredInt(map, 'idChat'),
        name: map['name'] as String,
        pathImage: map['pathImage'] as String?,
        memberCount: _requiredInt(map, 'memberCount'),
      );

  Map<String, dynamic> toMap() => {
    'idChat': idChat,
    'name': name,
    if (pathImage != null) 'pathImage': pathImage,
    'memberCount': memberCount,
  };

  @override
  List<Object?> get props => [idChat, name, pathImage, memberCount];
}

int _requiredInt(Map<String, dynamic> map, String key) {
  final value = DataParser.parseInt(map[key]);
  if (value == null) throw FormatException('Missing or invalid $key');
  return value;
}

double? _optionalDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

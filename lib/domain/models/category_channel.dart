import 'package:equatable/equatable.dart';

class CategoryChannel extends Equatable {
  final int? id;
  final int? serverId;
  final String? name;

  const CategoryChannel({this.id, this.serverId, this.name});

  factory CategoryChannel.fromMap(Map<String, dynamic> map) => CategoryChannel(
    id: (map['id'] as num?)?.toInt(),
    // categories/get.php serializes PHP objects directly.
    serverId: (map['serverId'] ?? map['fkServer'] as num?)?.toInt(),
    name: map['name'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'serverId': serverId,
    'name': name,
  };

  @override
  List<Object?> get props => [id, serverId, name];
}

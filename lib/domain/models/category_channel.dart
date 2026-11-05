import 'package:equatable/equatable.dart';

class CategoryChannel extends Equatable {
  final int? id;
  final int? serverId;
  final String? name;
  final int sortOrder;

  const CategoryChannel({
    this.id,
    this.serverId,
    this.name,
    this.sortOrder = 0,
  });

  factory CategoryChannel.fromMap(Map<String, dynamic> map) => CategoryChannel(
    id: (map['id'] as num?)?.toInt(),
    // categories/get.php serializes PHP objects directly.
    serverId: (map['serverId'] ?? map['fkServer'] as num?)?.toInt(),
    name: map['name'] as String?,
    sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'serverId': serverId,
    'name': name,
    'sortOrder': sortOrder,
  };

  @override
  List<Object?> get props => [id, serverId, name, sortOrder];
}

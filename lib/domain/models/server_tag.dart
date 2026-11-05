import 'package:equatable/equatable.dart';

class ServerTag extends Equatable {
  const ServerTag({this.id, required this.name, this.usageCount = 0});

  final int? id;
  final String name;
  final int usageCount;

  factory ServerTag.fromMap(Map<String, dynamic> map) => ServerTag(
    id: (map['id'] as num?)?.toInt(),
    name: map['name']?.toString() ?? '',
    usageCount: (map['usageCount'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'usageCount': usageCount,
  };

  @override
  List<Object?> get props => [id, name, usageCount];
}

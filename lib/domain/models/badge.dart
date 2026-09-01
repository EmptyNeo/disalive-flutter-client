// lib/domain/models/badge.dart

import 'package:equatable/equatable.dart';

class BadgeModel extends Equatable {
  final int? id;
  final String? name;
  final String? description;
  final String? iconPath;
  final String? color;

  const BadgeModel({
    this.id,
    this.name,
    this.description,
    this.iconPath,
    this.color,
  });

  // Фабричный метод из JSON (соответствует PHP fromArray)
  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      iconPath: map['iconPath'] ?? map['icon_path'],
      color: map['color'],
    );
  }

  // Преобразование в Map (соответствует PHP toArray)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'color': color,
    };
  }

  // copyWith метод
  BadgeModel copyWith({
    int? id,
    String? name,
    String? description,
    String? iconPath,
    String? color,
  }) {
    return BadgeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      color: color ?? this.color,
    );
  }

  bool get isEmpty => id == null;

  bool get isNotEmpty => id != null;

  @override
  List<Object?> get props => [id, name, description, iconPath, color];
}

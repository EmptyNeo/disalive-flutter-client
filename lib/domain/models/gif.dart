import 'package:equatable/equatable.dart';

class Gif extends Equatable {
  final int id;
  final List<String> tags;
  final String cloudSource;
  final String? cloudSource150;
  final String? cloudSource300;
  final String? cloudSource500;
  final int fileType;

  const Gif({
    required this.id,
    required this.tags,
    required this.cloudSource,
    this.cloudSource150,
    this.cloudSource300,
    this.cloudSource500,
    required this.fileType,
  });

  factory Gif.fromMap(Map<String, dynamic> json) {
    return Gif(
      id: json['id'] as int,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      cloudSource: json['cloudSource'] as String,
      cloudSource150: json['cloudSource150'] as String?,
      cloudSource300: json['cloudSource300'] as String?,
      cloudSource500: json['cloudSource500'] as String?,
      fileType: json['fileType'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tags': tags,
      'cloudSource': cloudSource,
      'cloudSource150': cloudSource150,
      'cloudSource300': cloudSource300,
      'cloudSource500': cloudSource500,
      'fileType': fileType,
    };
  }

  String get thumbnailUrl => cloudSource150 ?? cloudSource300 ?? cloudSource;

  String get previewUrl => cloudSource300 ?? cloudSource500 ?? cloudSource;

  String get fullUrl => cloudSource;

  String get primaryTag => tags.isNotEmpty ? tags.first : '';

  @override
  List<Object?> get props => [
    id,
    tags,
    cloudSource,
    cloudSource150,
    cloudSource300,
    cloudSource500,
    fileType,
  ];
}

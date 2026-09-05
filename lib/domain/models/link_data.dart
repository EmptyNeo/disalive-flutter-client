// lib/domain/models/link_data.dart
import 'package:equatable/equatable.dart';

class LinkData extends Equatable {
  final String? url;
  final String? title;
  final String? description;
  final String? image;
  final String? siteName;
  final String? video;

  const LinkData({
    this.url,
    this.title,
    this.description,
    this.image,
    this.siteName,
    this.video,
  });

  factory LinkData.fromMap(Map<String, dynamic> map) {
    return LinkData(
      url: map['url'],
      title: map['title'],
      description: map['description'],
      image: map['image'],
      siteName: map['siteName'],
      video: map['video'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (image != null) 'image': image,
      if (siteName != null) 'siteName': siteName,
      if (video != null) 'video': video,
    };
  }

  LinkData copyWith({
    String? url,
    String? title,
    String? description,
    String? image,
    String? siteName,
    String? video,
  }) {
    return LinkData(
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      siteName: siteName ?? this.siteName,
      video: video ?? this.video,
    );
  }

  bool get hasImage => image != null && image!.isNotEmpty;
  bool get hasVideo => video != null && video!.isNotEmpty;

  @override
  List<Object?> get props => [url, title, description, image, siteName, video];
}
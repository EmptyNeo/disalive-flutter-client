import 'package:disalive/domain/models/media_filter_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('photos, videos, files and audio share one file model', () {
    final samples = [
      ('image.jpg', 'jpg', 1.19, 'KB'),
      ('video.mp4', 'mp4', 5.05, 'MB'),
      ('archive.zip', 'zip', 6.32, 'KB'),
      ('audio.mp3', 'mp3', 177.27, 'KB'),
    ];

    for (final (name, extension, size, unit) in samples) {
      final file = MediaFilterFile.fromMap({
        'idFilesMessage': 4274,
        'pathFile': 'https://example.com/file.$extension?signature=abc',
        'originalName': name,
        'size': size,
        'unit': unit,
        'objectKey': 'uploads/file.$extension',
        'messageId': 16717,
        'time': '2026-10-23 10:20:30',
      });

      expect(file, isA<MediaFilterMessageItem>());
      expect(file.pathFile, contains('?signature=abc'));
      expect(file.originalName, name);
      expect(file.size, size);
      expect(file.thumbnailUrl, isNull);
      expect(file.time, '2026-10-23 10:20:30');
      expect(MediaFilterFile.fromMap(file.toMap()), file);
    }
  });

  test('file accepts an optional thumbnail and a numeric size string', () {
    final file = MediaFilterFile.fromMap({
      'idFilesMessage': '3925',
      'pathFile': 'https://example.com/document.docx',
      'size': '3.55',
      'messageId': '14850',
      'thumbnailUrl': 'https://example.com/preview.jpg',
    });

    expect(file.idFilesMessage, 3925);
    expect(file.idMessage, 14850);
    expect(file.size, 3.55);
    expect(file.thumbnailUrl, 'https://example.com/preview.jpg');
  });

  test('link retains its message and preview metadata', () {
    final link = MediaFilterLink.fromMap({
      'link': 'https://xbox-dns.ru/#setup',
      'messageId': 16583,
      'time': '2026-09-05 00:48:50',
      'fkSender': 1,
      'domain': 'xbox-dns.ru',
      'title': 'Xbox DNS',
      'description': '',
      'image': null,
    });

    expect(link, isA<MediaFilterMessageItem>());
    expect(link.idMessage, 16583);
    expect(link.image, isNull);
    expect(link.description, '');
    expect(MediaFilterLink.fromMap(link.toMap()), link);
  });

  test('mutual group retains its chat fields', () {
    final group = MediaFilterMutualGroup.fromMap({
      'idChat': 591,
      'name': 'Qwe, Test',
      'pathImage': '/resources/DefaultGroupImage.png',
      'memberCount': 4,
    });

    expect(group.idChat, 591);
    expect(group.memberCount, 4);
    expect(MediaFilterMutualGroup.fromMap(group.toMap()), group);
  });

  test('mutual server parses camelCase response fields', () {
    final server = MediaFilterMutualServer.fromMap({
      'idServer': '12',
      'name': 'Community',
      'pathAvatar': '/resources/server.png',
      'memberCount': '42',
    });

    expect(server.idServer, 12);
    expect(server.name, 'Community');
    expect(server.pathAvatar, '/resources/server.png');
    expect(server.memberCount, 42);
  });

  test('missing identifiers fail instead of becoming zero', () {
    expect(
      () => MediaFilterFile.fromMap({
        'pathFile': 'https://example.com/image.jpg',
        'messageId': 1,
      }),
      throwsFormatException,
    );
  });
}

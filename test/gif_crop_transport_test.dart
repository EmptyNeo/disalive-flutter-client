import 'dart:io';

import 'package:disalive/domain/services/http_client_service.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('GIF crop sends source and rectangle, then returns binary GIF', () async {
    final directory = await Directory.systemTemp.createTemp('disalive_gif_crop_');
    final image = File('${directory.path}/source.gif');
    await image.writeAsBytes('GIF89a'.codeUnits);
    final responseBytes = 'GIF89a cropped'.codeUnits;
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/gifs/crop/');
      expect(request.body, contains('name="image"'));
      expect(request.body, contains('name="x"'));
      expect(request.body, contains('name="height"'));
      return http.Response.bytes(responseBytes, 200, headers: {'content-type': 'image/gif'});
    });
    final service = HttpClientService(client: client, secureStorage: SecureStorageService());
    try {
      final result = await service.postMultipartBytes(
        endpoint: 'gifs/crop/',
        data: {'x': 1, 'y': 2, 'width': 32, 'height': 20},
        files: {'image': [image]},
        requireAuth: false,
      );
      result.fold(
        (failure) => fail(failure.message),
        (bytes) => expect(bytes, responseBytes),
      );
    } finally {
      service.dispose();
      await directory.delete(recursive: true);
    }
  });
}

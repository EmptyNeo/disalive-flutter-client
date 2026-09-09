import 'dart:convert';
import 'dart:io';

class UtilFile {
  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    }
    return '$bytes Б';
  }

  static Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);
    final mimeType = _getMimeType(file.path);
    return 'data:$mimeType;base64,$base64';
  }

  static String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'bmp':
        return 'image/bmp';
      case 'ico':
        return 'image/x-icon';
      case 'apng':
        return 'image/apng';
      case 'avif':
        return 'image/avif';
      default:
        return 'application/octet-stream';
    }
  }
}

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Сервисный класс для управления видео-контентом
class VideoHandler {
  VideoHandler._();

  /// Генерирует путь к файлу миниатюры (thumbnail) для видео
  static Future<String?> generateThumbnail(String source) async {
    try {
      final tempDir = await getTemporaryDirectory();

      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: source,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 400, // Оптимальное качество для превью в чате
        quality: 75,
      );

      return thumbnail;
    } catch (e) {
      // В случае ошибки возвращаем null, виджет обработает это
      return null;
    }
  }

  /// Создает и инициализирует VideoPlayerController
  static Future<VideoPlayerController> createController(
      String source,
      bool isNetwork,
      ) async {
    final controller = isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(source))
        : VideoPlayerController.file(File(source));

    await controller.initialize();

    // Опционально: можно включить зацикливание, если это гифка/короткое видео
    // controller.setLooping(true);

    return controller;
  }
}
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioDuration {
  /// Получает реальную длительность аудиофайла в секундах (как double)
  /// на основе метаданных файла, аналогично JS new Audio().duration
  static Future<double> getDurationInSeconds(File file) async {
    try {
      final player = AudioPlayer();

      // Загружаем только метаданные, не проигрывая файл
      await player.setFilePath(file.path);
      final duration = player.duration;

      // Сразу освобождаем ресурсы плеера
      await player.dispose();

      if (duration != null) {
        // Переводим миллисекунды в секунды с плавающей точкой
        return duration.inMilliseconds / 1000.0;
      }

      return 0.0;
    } catch (e) {
      debugPrint('Не удалось получить длительность аудио: $e');
      return 0.0;
    }
  }
}
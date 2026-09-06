// lib/presentation/features/message/widgets/media/grids/audios_grid.dart
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/audio_item.dart';
import 'package:flutter/cupertino.dart';

/// Список аудио-вложений сообщения — каждый файл отдельной строкой через
/// [AudioItem], друг под другом (тот же паттерн, что у FilesColumn).
class AudiosGrid extends StatelessWidget {
  const AudiosGrid({super.key, required this.audios, this.isMine = false});

  final List<FileMessage> audios;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (audios.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final audio in audios)
          AudioItem(
            key: ValueKey(audio.id ?? audio.objectKey ?? audio.pathFile),
            file: audio,
            isMine: isMine,
          ),
      ],
    );
  }
}

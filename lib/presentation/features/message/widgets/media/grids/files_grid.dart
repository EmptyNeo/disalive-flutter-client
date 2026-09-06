// lib/presentation/features/message/widgets/media/grids/files_column.dart
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/file_item.dart';
import 'package:flutter/cupertino.dart';

/// Список обычных файлов-вложений сообщения (не изображений) — каждый
/// файл отдельной строкой через [FileItem], друг под другом.
class FilesGrid extends StatelessWidget {
  const FilesGrid({super.key, required this.files, this.isMine = false});

  final List<FileMessage> files;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final file in files)
          FileItem(
            key: ValueKey(file.id ?? file.objectKey ?? file.urlPath),
            file: file,
            isMine: isMine,
          ),
      ],
    );
  }
}

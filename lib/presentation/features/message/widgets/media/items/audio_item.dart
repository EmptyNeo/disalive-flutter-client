// lib/presentation/features/message/widgets/media/audio_item.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/presentation/features/message/widgets/controllers/audio_player.dart';
import 'package:flutter/cupertino.dart';

/// Один аудио-файл в сообщении — карточка (тот же визуальный язык, что у
/// FileItem) с именем файла (если есть) и плеером [AudioPlayerWidget].
class AudioItem extends StatelessWidget {
  const AudioItem({super.key, required this.file, this.isMine = false});

  final FileMessage file;

  /// Влияет только на цвета — чтобы виджет было видно и на синем бабле
  /// (свои сообщения), и на сером (чужие).
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final path = file.pathFile;
    if (path == null || path.isEmpty) return const SizedBox.shrink();

    final name = file.originalName ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (isMine ? AppColors.onBlurple : AppColors.white).withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (name.isNotEmpty) ...[
            Text(
              name,
              style: AppText.lowTextStyle.copyWith(
                color: isMine ? AppColors.onBlurple : AppColors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
          ],
          AudioPlayerWidget(
            url: path,
            duration: file.duration ?? 0,
            isMine: isMine,
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

/// Сохраняет открытую фотографию или видео в галерею устройства.
class MediaSaveButton extends StatefulWidget {
  const MediaSaveButton({super.key, required this.attachment});

  final FileMessage attachment;

  @override
  State<MediaSaveButton> createState() => _MediaSaveButtonState();
}

class _MediaSaveButtonState extends State<MediaSaveButton> {
  final Dio _dio = Dio();
  CancelToken? _cancelToken;
  bool _saving = false;

  @override
  void dispose() {
    _cancelToken?.cancel();
    _dio.close();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final source = widget.attachment.urlPath;
    if (source.isEmpty) return;

    setState(() => _saving = true);
    _cancelToken = CancelToken();
    File? temporaryVideo;
    try {
      final originalName = widget.attachment.originalName;
      final fallbackExtension = widget.attachment.isVideoFile ? 'mp4' : 'jpg';
      final name =
          (originalName == null || originalName.isEmpty
                  ? 'disalive_${widget.attachment.id ?? DateTime.now().millisecondsSinceEpoch}.$fallbackExtension'
                  : originalName)
              .replaceAll(RegExp(r'[\\/]'), '_');

      if (widget.attachment.isVideoFile) {
        final directory = await getTemporaryDirectory();
        temporaryVideo = File(
          '${directory.path}/disalive_${DateTime.now().microsecondsSinceEpoch}_$name',
        );
        if (source.startsWith('http')) {
          await _dio.download(
            source,
            temporaryVideo.path,
            cancelToken: _cancelToken,
          );
        } else {
          await File(source).copy(temporaryVideo.path);
        }
        await PhotoManager.editor.saveVideo(temporaryVideo, title: name);
      } else {
        final Uint8List bytes;
        if (source.startsWith('http')) {
          final response = await _dio.get<List<int>>(
            source,
            options: Options(responseType: ResponseType.bytes),
            cancelToken: _cancelToken,
          );
          bytes = Uint8List.fromList(response.data ?? const []);
        } else {
          bytes = await File(source).readAsBytes();
        }
        if (bytes.isEmpty) throw StateError('Медиафайл пуст');
        await PhotoManager.editor.saveImage(bytes, filename: name);
      }

      if (mounted) {
        CustomToast.open(
          context: context,
          message: 'Сохранено в галерею',
          icon: CupertinoIcons.checkmark_circle_fill,
          color: CupertinoColors.activeGreen,
        );
      }
    } catch (_) {
      if (mounted && !(_cancelToken?.isCancelled ?? false)) {
        CustomToast.open(
          context: context,
          message: 'Не удалось сохранить медиа',
        );
      }
    } finally {
      if (temporaryVideo != null) {
        try {
          if (await temporaryVideo.exists()) await temporaryVideo.delete();
        } on FileSystemException {
          // Очистка временного файла не должна прерывать сохранение в галерею.
        }
      }
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _saving
      ? const SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: CupertinoActivityIndicator(color: CupertinoColors.white),
          ),
        )
      : GlassIconButton(icon: CupertinoIcons.arrow_down_circle, onTap: _save);
}

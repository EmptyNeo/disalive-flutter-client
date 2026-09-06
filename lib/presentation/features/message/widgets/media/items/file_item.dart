// lib/presentation/features/message/widgets/file_item.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/ui/download_status.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/presentation/features/message/widgets/media/painters/progress_ring.dart';
import 'package:disalive/presentation/utils/ui/util_file.dart';
import 'package:flutter/cupertino.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// Один файл-вложение в сообщении: иконка по типу, имя, размер
/// ([FileMessage.formattedSize]) и кнопка скачивания на устройство.
/// Во время загрузки кнопка превращается в кольцевой прогресс-индикатор,
/// а подпись под именем файла показывает "скачано / всего" в КБ/МБ/ГБ.
class FileItem extends StatefulWidget {
  const FileItem({super.key, required this.file, this.isMine = false});

  final FileMessage file;
  final bool isMine;

  @override
  State<FileItem> createState() => _FileItemState();
}

class _FileItemState extends State<FileItem> {
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  DownloadStatus _status = DownloadStatus.idle;
  int _received = 0;
  int _total = 0;

  String? _savedPath;

  @override
  void initState() {
    super.initState();
    _checkAlreadyDownloaded();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<String> _targetPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final url = widget.file.pathFile ?? '';
    final fileName = widget.file.originalName ?? url.split('/').last;
    return '${dir.path}/$fileName';
  }

  Future<void> _checkAlreadyDownloaded() async {
    if (widget.file.pathFile == null || widget.file.pathFile!.isEmpty) return;

    final path = await _targetPath();
    if (!mounted) return;
    if (File(path).existsSync()) {
      setState(() {
        _savedPath = path;
        _status = DownloadStatus.done;
      });
    }
  }

  Future<void> _startDownload() async {
    final url = widget.file.pathFile;
    if (url == null || url.isEmpty) return;

    setState(() {
      _status = DownloadStatus.downloading;
      _received = 0;
      _total = 0;
    });

    _cancelToken = CancelToken();

    try {
      final savePath = await _targetPath();

      await _dio.download(
        url,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            _total = total;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _savedPath = savePath;
        _status = DownloadStatus.done;
      });
    } catch (_) {
      if (!mounted) return;
      if (_cancelToken?.isCancelled ?? false) {
        setState(() => _status = DownloadStatus.idle);
      } else {
        setState(() => _status = DownloadStatus.error);
      }
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
  }

  Future<void> _openFile() async {
    final path = _savedPath;
    if (path == null) return;

    final result = await OpenFile.open(path);
    if (!mounted) return;

    if (result.type == ResultType.fileNotFound) {
      setState(() {
        _status = DownloadStatus.idle;
        _savedPath = null;
      });
    }
  }

  String _subtitle() {
    switch (_status) {
      case DownloadStatus.downloading:
        final total = UtilFile.formatBytes(_total);
        return '${UtilFile.formatBytes(_received)} / $total';
      case DownloadStatus.done:
        return 'Загружено · ${widget.file.formattedSize}';
      case DownloadStatus.error:
        return 'Не удалось скачать · нажмите, чтобы повторить';
      case DownloadStatus.idle:
        return widget.file.formattedSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitleColor = widget.isMine
        ? AppColors.onBlurple.withValues(alpha: 0.75)
        : AppColors.greyple;
    final nameColor = widget.isMine ? AppColors.onBlurple : AppColors.white;

    return GestureDetector(
      onTap: _status == DownloadStatus.done ? _openFile : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: (widget.isMine ? AppColors.onBlurple : AppColors.white)
              .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildFileIcon(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.file.originalName ?? 'Файл',
                    style: AppText.lowTextStyle.copyWith(
                      color: nameColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(),
                    style: AppText.lowTextStyle.copyWith(
                      color: subtitleColor,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    final accent = widget.isMine ? AppColors.onBlurple : AppColors.blurple;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(_iconForFile(), size: 18, color: accent),
    );
  }

  IconData _iconForFile() {
    switch (widget.file.extension.toLowerCase()) {
      case 'pdf':
        return CupertinoIcons.doc_richtext;
      case 'zip':
      case 'rar':
      case '7z':
        return CupertinoIcons.archivebox_fill;
      case 'doc':
      case 'docx':
        return CupertinoIcons.doc_text_fill;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return CupertinoIcons.square_list_fill;
      default:
        return CupertinoIcons.doc_fill;
    }
  }

  Widget _buildAction() {
    final accent = widget.isMine ? AppColors.onBlurple : AppColors.blurple;

    switch (_status) {
      case DownloadStatus.idle:
        return GestureDetector(
          onTap: _startDownload,
          child: Icon(
            CupertinoIcons.arrow_down_circle,
            size: 28,
            color: accent,
          ),
        );
      case DownloadStatus.downloading:
        final progress = _total > 0 ? _received / _total : null;
        return GestureDetector(
          onTap: _cancelDownload,
          child: ProgressRing(progress: progress, color: accent),
        );
      case DownloadStatus.done:
        return const Icon(
          CupertinoIcons.checkmark_circle_fill,
          size: 28,
          color: AppColors.successGreen,
        );
      case DownloadStatus.error:
        return GestureDetector(
          onTap: _startDownload,
          child: const Icon(
            CupertinoIcons.arrow_clockwise_circle,
            size: 28,
            color: CupertinoColors.systemRed,
          ),
        );
    }
  }
}

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/app_update.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<void> showAppUpdateSheet(BuildContext context, AppUpdate update) =>
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => _AppUpdateSheet(update: update),
    );

class _AppUpdateSheet extends StatefulWidget {
  const _AppUpdateSheet({required this.update});

  final AppUpdate update;

  @override
  State<_AppUpdateSheet> createState() => _AppUpdateSheetState();
}

class _AppUpdateSheetState extends State<_AppUpdateSheet> {
  static const _installChannel = MethodChannel('com.disalive/update');
  bool _downloading = false;
  bool _needsInstallPermission = false;
  String? _downloadedPath;
  double? _progress;
  String? _error;

  Future<void> _install() async {
    if (_downloading) return;
    final uri = Uri.tryParse(widget.update.downloadUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      setState(() => _error = 'Ссылка для загрузки недоступна.');
      return;
    }

    setState(() {
      _downloading = true;
      _progress = null;
      _error = null;
    });
    try {
      final canInstall =
          await _installChannel.invokeMethod<bool>('canInstallPackages') ?? false;
      if (!canInstall) {
        if (mounted) setState(() => _needsInstallPermission = true);
        return;
      }
      final file = _downloadedPath == null
          ? await _download(uri)
          : File(_downloadedPath!);
      if (await file.length() == 0) {
        throw const FileSystemException('Загруженный файл пуст.');
      }
      final result = await OpenFile.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type != ResultType.done) {
        throw StateError(result.message);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Не удалось загрузить или открыть установщик. Попробуйте ещё раз.');
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<File> _download(Uri uri) async {
    final directory = await getTemporaryDirectory();
    final version = widget.update.version.replaceAll(RegExp(r'[^0-9.]'), '');
    final file = File('${directory.path}/disalive-$version.apk');
    await Dio().download(
      uri.toString(),
      file.path,
      onReceiveProgress: (received, total) {
        if (!mounted) return;
        setState(() => _progress = total > 0 ? received / total : null);
      },
    );
    _downloadedPath = file.path;
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          decoration: BoxDecoration(
            color: AppColors.darkGrey,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.greyple,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Доступно обновление ${widget.update.version}',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.update.changelog.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(widget.update.changelog,
                      style: TextStyle(color: AppColors.white)),
                ],
                if (widget.update.about.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(widget.update.about.trim(),
                      style: TextStyle(color: AppColors.greyple, height: 1.4)),
                ],
                if (_downloading) ...[
                  const SizedBox(height: 20),
                  if (_progress == null)
                    const CupertinoActivityIndicator()
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Загрузка ${(_progress! * 100).round()}%',
                            style: TextStyle(color: AppColors.white)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            color: AppColors.blurple,
                            backgroundColor: AppColors.divider,
                          ),
                        ),
                      ],
                    ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: TextStyle(color: AppColors.errorRed)),
                ],
                if (_needsInstallPermission) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Разрешите установку приложений из Disalive в настройках Android, затем вернитесь и нажмите «Скачать и установить».',
                    style: TextStyle(color: AppColors.greyple),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _installChannel.invokeMethod<void>(
                      'openInstallSettings',
                    ),
                    child: const Text('Открыть настройки'),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: AppColors.blurple,
                    onPressed: _downloading ? null : _install,
                    child: const Text('Скачать и установить'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: _downloading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Позже'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:flutter_rustore_update/flutter_rustore_update.dart';

Future<void> showRuStoreUpdateSheet(
  BuildContext context, {
  required bool downloaded,
}) => showCupertinoModalPopup<void>(
  context: context,
  builder: (_) => _RuStoreUpdateSheet(initiallyDownloaded: downloaded),
);

class _RuStoreUpdateSheet extends StatefulWidget {
  const _RuStoreUpdateSheet({required this.initiallyDownloaded});

  final bool initiallyDownloaded;

  @override
  State<_RuStoreUpdateSheet> createState() => _RuStoreUpdateSheetState();
}

class _RuStoreUpdateSheetState extends State<_RuStoreUpdateSheet> {
  StreamSubscription<RequestResponse>? _subscription;
  late bool _downloaded;
  bool _downloading = false;
  bool _busy = false;
  double? _progress;

  @override
  void initState() {
    super.initState();
    _downloaded = widget.initiallyDownloaded;
    _subscription = RustoreUpdateClient.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _downloaded = state.installStatusValue == InstallStatus.downloaded;
        _downloading = state.installStatusValue == InstallStatus.downloading;
        _progress = _downloading ? state.downloadProgress : null;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _startUpdate() async {
    if (_busy || _downloading) return;
    setState(() => _busy = true);
    try {
      if (_downloaded) {
        await RustoreUpdateClient.completeUpdateFlexible();
      } else {
        // AppUpdateInfo is single-use. Fetch a fresh one for each attempt.
        final info = await RustoreUpdateClient.info();
        if (info.installStatusValue == InstallStatus.downloaded) {
          if (mounted) setState(() => _downloaded = true);
          await RustoreUpdateClient.completeUpdateFlexible();
        } else if (info.updateAvailabilityValue ==
            UpdateAvailability.available) {
          await RustoreUpdateClient.download();
        }
      }
    } catch (_) {
      // RuStore owns the download and installation flow. A failed or canceled
      // request should not interrupt the app; the user may retry later.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.darkGrey,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
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
                _downloaded ? 'Обновление готово' : 'Доступно обновление',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _downloaded
                    ? 'Установите новую версию через RuStore.'
                    : 'Новая версия Disalive доступна в RuStore.',
                style: TextStyle(color: AppColors.greyple, height: 1.4),
              ),
              if (_downloading) ...[
                const SizedBox(height: 18),
                Text(
                  _progress == null
                      ? 'Загрузка обновления…'
                      : 'Загрузка ${(_progress! * 100).round()}%',
                  style: TextStyle(color: AppColors.white),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress,
                  color: AppColors.blurple,
                  backgroundColor: AppColors.divider,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppColors.blurple,
                  onPressed: _busy || _downloading ? null : _startUpdate,
                  child: Text(
                    _downloaded ? 'Установить' : 'Обновить через RuStore',
                    style: TextStyle(
                      color: AppColors.onBlurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(),
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

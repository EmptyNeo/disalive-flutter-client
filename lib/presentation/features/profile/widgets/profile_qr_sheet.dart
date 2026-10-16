import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/user.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfileQrSheet {
  static Future<void> show(BuildContext context, UserModel user) async {
    final username = user.username;
    if (username == null || username.isEmpty) return;

    final link =
        'https://disalive.ru/app/#profiles/${Uri.encodeComponent(username)}';

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoPopupSurface(
        child: SizedBox(
          width: MediaQuery.sizeOf(sheetContext).width,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Профиль ${user.getDisplayName}',
                    style: AppText.highTextStyle.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(data: link, size: 220),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    link,
                    style: AppText.mediumTextStyle.copyWith(
                      color: AppColors.greyple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton.filled(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: link));
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                      if (context.mounted) {
                        CustomToast.open(
                          context: context,
                          icon: CupertinoIcons.checkmark_alt,
                          color: AppColors.green,
                          message: 'Ссылка на профиль скопирована',
                        );
                      }
                    },
                    child: const Text('Скопировать ссылку'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

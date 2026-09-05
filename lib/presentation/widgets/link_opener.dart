// presentation/utils/link_opener.dart
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

/// Открывает ссылку во внешнем браузере, но только после подтверждения —
/// случайный тап по превью или ссылке в тексте не должен уводить человека
/// на непроверенный сайт без спроса.
///
/// Переиспользуемый: не завязан на превью ссылок конкретно, годится для
/// любой ссылки в чате (текст сообщения, invite-карточка и т.п.).
class LinkOpener {
  const LinkOpener._();

  static Future<void> confirmAndOpen(BuildContext context, String url) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Открыть ссылку?'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(url, style: const TextStyle(fontSize: 13)),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Открыть'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Не получилось открыть ссылку'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ок'),
            ),
          ],
        ),
      );
    }
  }
}
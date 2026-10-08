// presentation/utils/link_opener.dart
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkOpener {
  const LinkOpener._();

  static Future<void> confirmAndOpen(BuildContext context, String url) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: "Открыть ссылку",
      description: url,
    );

    if (confirmed != true) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      await showConfirmationDialog(
        context,
        title: 'Ошибка',
        description: 'Не получилось открыть ссылку',
        confirmText: 'ОК',
        cancelText: null,
      );
    }
  }
}

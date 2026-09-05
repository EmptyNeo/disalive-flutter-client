// presentation/utils/app_clipboard.dart
import 'package:disalive/presentation/utils/app_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Копирование текста в буфер обмена с тактильным откликом и тостом —
/// без обратной связи человек не понимает, сработал ли тап вообще.
class AppClipboard {
  const AppClipboard._();

  static Future<void> copyText(
      BuildContext context,
      String text, {
        String feedbackMessage = 'Скопировано',
      }) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (context.mounted) {
      AppToast.show(context, feedbackMessage);
    }
  }
}
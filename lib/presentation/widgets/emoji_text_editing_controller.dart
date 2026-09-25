import 'package:disalive/presentation/utils/ui/emoji_text_parser.dart';
import 'package:flutter/cupertino.dart';
import 'package:disalive/app/theme/app_theme.dart';

class EmojiTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Если текст пустой, возвращаем стандартный спан
    if (text.isEmpty) {
      return TextSpan(style: style);
    }

    final spans = EmojiTextParser.parse(
      text,
      baseTextStyle:
          style ?? AppText.mediumTextStyle.copyWith(color: AppColors.white),
      emojiSize: 18,
    );

    return TextSpan(style: style, children: spans);
  }
}

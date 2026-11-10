import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/services/emojis_handler.dart';
import 'package:disalive/presentation/widgets/emoji_widget.dart';
import 'package:disalive/presentation/widgets/emoji_token.dart';
import 'package:flutter/cupertino.dart';

class RoleEmoji extends StatelessWidget {
  const RoleEmoji(this.value, {super.key, this.size = 22});

  final String? value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final token = value?.trim() ?? '';
    if (token.isEmpty) return const SizedBox.shrink();
    final serverMatch = RegExp(
      r'^\[(server_[a-z]+):(\d+)\]$',
    ).firstMatch(token);
    if (serverMatch != null) {
      return EmojiToken(
        category: serverMatch.group(1)!,
        id: serverMatch.group(2)!,
        token: token,
        size: size,
        style: TextStyle(color: AppColors.white, fontSize: size),
        animate: false,
      );
    }
    final emoji = EmojisHandler.instance.getEmojiByName(token);
    final sheet = emoji?.categoryName == null
        ? null
        : EmojisHandler.instance.getSheetDataByCategory(emoji!.categoryName!);
    if (emoji != null && sheet != null) {
      return EmojiWidget(
        emoji: emoji,
        sheetData: sheet,
        size: size,
        animate: false,
      );
    }
    return Text(
      token,
      style: TextStyle(color: AppColors.white, fontSize: size),
    );
  }
}

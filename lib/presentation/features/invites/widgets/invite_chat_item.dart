import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

/// Строка личного чата с действием отправки. Подходит и для других списков.
class InviteChatItem extends StatelessWidget {
  const InviteChatItem({
    super.key,
    required this.chat,
    required this.onSend,
    this.isSending = false,
    this.isSent = false,
  });

  final Chat chat;
  final VoidCallback? onSend;
  final bool isSending;
  final bool isSent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    child: Row(
      children: [
        BuildAvatar(
          url: chat.urlAvatar,
          wh: 38,
          size: 25,
          status: chat.user?.status,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            chat.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.white, fontSize: 15),
          ),
        ),
        const SizedBox(width: 8),
        CupertinoButton(
          key: Key('send_invite_${chat.id}'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          minimumSize: const Size(80, 32),
          color: AppColors.actionGrey,
          onPressed: isSent || isSending ? null : onSend,
          child: isSending
              ? const CupertinoActivityIndicator()
              : Text(
                  isSent ? 'Отправлено' : 'Отправить',
                  style: TextStyle(color: AppColors.white, fontSize: 13),
                ),
        ),
      ],
    ),
  );
}

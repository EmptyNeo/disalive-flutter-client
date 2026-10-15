import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:flutter/cupertino.dart';

class ChannelServerItem extends StatelessWidget {
  final ChannelServer channel;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ChannelServerItem({
    super.key,
    required this.channel,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final unread = channel.newMessagesCount;
    final isVoice = channel.type == 'voice';
    return Semantics(
      button: true,
      label: channel.chatName ?? 'Канал',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.highlight : AppColors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isVoice ? CupertinoIcons.speaker_2_fill : CupertinoIcons.number,
                size: 18,
                color: isSelected ? AppColors.white : AppColors.greyple,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  channel.chatName?.isNotEmpty == true
                      ? channel.chatName!
                      : 'Без названия',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.mediumTextStyle.copyWith(
                    color: isSelected || unread > 0
                        ? AppColors.white
                        : AppColors.greyple,
                    fontWeight: unread > 0 || isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (channel.isPrivate)
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Icon(
                    CupertinoIcons.lock_fill,
                    size: 13,
                    color: AppColors.greyple,
                  ),
                ),
              if (unread > 0) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  constraints: const BoxConstraints(minWidth: 20),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/models/call_data.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

class ChannelCallParticipants extends StatelessWidget {
  const ChannelCallParticipants({
    super.key,
    required this.participants,
    required this.isCollapsed,
    required this.onToggle,
  });

  final List<CallParticipant> participants;
  final bool isCollapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 42, right: 16, bottom: 4),
    child: Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          child: SizedBox(
            height: 25,
            child: Row(
              children: [
                Icon(
                  isCollapsed
                      ? CupertinoIcons.chevron_right
                      : CupertinoIcons.chevron_down,
                  size: 11,
                  color: AppColors.greyple,
                ),
                const SizedBox(width: 6),
                Text(
                  'В звонке · ${participants.length}',
                  style: AppText.lowTextStyle.copyWith(
                    color: AppColors.greyple,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isCollapsed)
          for (final participant in participants)
            SizedBox(
              height: 29,
              child: Row(
                children: [
                  BuildAvatar(
                    url: Domain.transformUrl(participant.avatarPath),
                    wh: 20,
                    size: 13,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      participant.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.lowTextStyle.copyWith(
                        color: AppColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(
                    participant.microphoneEnabled
                        ? CupertinoIcons.mic_fill
                        : CupertinoIcons.mic_slash_fill,
                    size: 13,
                    color: participant.microphoneEnabled
                        ? AppColors.greyple
                        : AppColors.errorRed,
                  ),
                  const SizedBox(width: 7),
                  Icon(
                    participant.headphonesEnabled == false
                        ? CupertinoIcons.volume_off
                        : CupertinoIcons.headphones,
                    size: 13,
                    color: participant.headphonesEnabled == false
                        ? AppColors.errorRed
                        : AppColors.greyple,
                  ),
                ],
              ),
            ),
      ],
    ),
  );
}

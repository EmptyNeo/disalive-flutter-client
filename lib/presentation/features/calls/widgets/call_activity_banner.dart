import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class CallActivityBanner extends StatelessWidget {
  const CallActivityBanner({
    super.key,
    required this.participantCount,
    this.isCurrentCall = false,
    this.onJoin,
  });

  final int participantCount;
  final bool isCurrentCall;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
    child: Container(
      height: 42,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.waveform, size: 18, color: AppColors.blurple),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'В звонке: $participantCount',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.mediumTextStyle.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoButton(
            key: const ValueKey('join_active_call'),
            padding: EdgeInsets.zero,
            minimumSize: const Size(34, 34),
            onPressed: onJoin,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.blurple,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCurrentCall
                    ? CupertinoIcons.arrow_up_left_arrow_down_right
                    : CupertinoIcons.phone_arrow_up_right,
                size: 17,
                color: AppColors.onBlurple,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

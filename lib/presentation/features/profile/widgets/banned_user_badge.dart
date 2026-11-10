import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class BannedUserBadge extends StatelessWidget {
  const BannedUserBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.errorRed.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.exclamationmark_shield,
          size: 13,
          color: AppColors.errorRed,
        ),
        const SizedBox(width: 5),
        Text(
          'Заблокирован',
          style: TextStyle(
            color: AppColors.errorRed,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

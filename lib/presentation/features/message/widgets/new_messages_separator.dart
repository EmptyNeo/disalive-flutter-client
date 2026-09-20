import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class NewMessagesSeparator extends StatelessWidget {
  const NewMessagesSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.red.withValues(alpha: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              'Новые сообщения',
              style: AppText.lowTextStyle.copyWith(
                color: AppColors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.errorRed.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
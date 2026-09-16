import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class ProfileThoughtsBubble extends StatelessWidget {
  final Color colorOutline;
  final String text;

  const ProfileThoughtsBubble({
    super.key,
    required this.colorOutline,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mainBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorOutline),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: AppText.lowTextStyle.copyWith(
          color: AppColors.white,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

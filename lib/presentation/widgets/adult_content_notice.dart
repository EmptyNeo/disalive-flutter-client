import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class AdultContentNotice extends StatelessWidget {
  const AdultContentNotice({super.key, required this.description});

  final String description;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.lightGrey,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(CupertinoIcons.lock_shield, color: AppColors.greyple, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Контент для взрослых',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(color: AppColors.greyple)),
            ],
          ),
        ),
      ],
    ),
  );
}

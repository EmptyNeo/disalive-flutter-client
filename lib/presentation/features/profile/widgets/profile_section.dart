// presentation/features/profile/widgets/profile_section.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class ProfileSection extends StatelessWidget {
  final String title;
  final String content;

  const ProfileSection({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.lowTextStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.greyple,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppText.mediumTextStyle.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

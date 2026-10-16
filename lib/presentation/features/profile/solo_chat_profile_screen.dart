import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/presentation/features/profile/widgets/media_stats_section.dart';
import 'package:disalive/presentation/widgets/custom_back_button.dart';
import 'package:flutter/cupertino.dart';

class SoloChatProfileScreen extends StatelessWidget {
  const SoloChatProfileScreen({
    super.key,
    required this.chat,
    this.onMediaCategoryTap,
  });

  final Chat chat;
  final ValueChanged<MediaStatsCategory>? onMediaCategoryTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.mainBackground,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.12),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 54, 16, 24),
                    children: [
                      Text(
                        'Избранное',
                        textAlign: TextAlign.left,
                        style: AppText.highTextStyle.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 28),
                      MediaStatsSection(
                        chatId: chat.id,
                        onCategoryTap: onMediaCategoryTap,
                      ),
                    ],
                  ),
                  const CustomBackButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/custom_back_button.dart';
import 'package:disalive/presentation/widgets/service_verified_badge.dart';
import 'package:flutter/cupertino.dart';

class ServiceChatProfileScreen extends StatelessWidget {
  const ServiceChatProfileScreen({super.key});

  static const _backgroundColor = Color(0xFF111E30);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Container(
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.12),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                        child: Column(
                          children: [
                            const BuildAvatar(
                              chatType: ChatType.service,
                              wh: 84,
                              size: 48,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Уведомления Disalive',
                                    style: AppText.highTextStyle.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const ServiceVerifiedBadge(),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'служебные уведомления',
                              style: AppText.lowTextStyle.copyWith(
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
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

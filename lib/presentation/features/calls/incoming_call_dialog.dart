import 'dart:async';
import 'dart:ui';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/features/calls/bloc/call_bloc.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

Future<bool> showIncomingCallDialog(
  BuildContext context,
  IncomingCall call,
) async {
  Timer? timeout;
  try {
    return await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Отклонить звонок',
          barrierColor: CupertinoColors.black.withValues(alpha: 0.55),
          transitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (dialogContext, animation, secondaryAnimation) {
            timeout ??= Timer(const Duration(seconds: 30), () {
              if (dialogContext.mounted) Navigator.of(dialogContext).pop(false);
            });
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.darkGrey.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipOval(
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: call.isNsfw ? 12 : 0,
                                sigmaY: call.isNsfw ? 12 : 0,
                              ),
                              child: BuildAvatar(
                                url: call.pathImage,
                                wh: 76,
                                size: 34,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            call.displayName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.highTextStyle.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            call.streamType == 'video'
                                ? 'Входящий видеозвонок'
                                : 'Входящий звонок',
                            style: AppText.mediumTextStyle.copyWith(
                              color: AppColors.greyple,
                            ),
                          ),
                          if (call.username case final username?
                              when username.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '@$username',
                              style: AppText.lowTextStyle.copyWith(
                                color: AppColors.greyple,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _CallButton(
                                  icon: CupertinoIcons.phone_down_fill,
                                  label: 'Отклонить',
                                  color: AppColors.errorRed,
                                  onTap: () =>
                                      Navigator.of(dialogContext).pop(false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CallButton(
                                  icon: CupertinoIcons.phone_fill,
                                  label: 'Ответить',
                                  color: AppColors.green,
                                  onTap: () =>
                                      Navigator.of(dialogContext).pop(true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ) ??
        false;
  } finally {
    timeout?.cancel();
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.symmetric(vertical: 12),
    color: color,
    borderRadius: BorderRadius.circular(14),
    onPressed: onTap,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: CupertinoColors.white),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.mediumTextStyle.copyWith(
              color: CupertinoColors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

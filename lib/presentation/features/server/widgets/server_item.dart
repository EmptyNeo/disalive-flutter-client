import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class ServerItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isSpecial;
  final bool isAction;

  const ServerItem({
    super.key,
    required this.icon,
    required this.isActive,
    this.isSpecial = false,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: isActive ? 32 : 0,
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),

        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.blurple
                : CupertinoColors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(isActive ? 16 : 24),
          ),
          child: Icon(
            icon,
            color: isAction
                ? CupertinoColors.activeGreen
                : CupertinoColors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class ServiceVerifiedBadge extends StatelessWidget {
  const ServiceVerifiedBadge({super.key, this.size = 15});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Официальный служебный чат',
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.blurple,
        shape: BoxShape.circle,
      ),
      child: Icon(
        CupertinoIcons.check_mark,
        size: size * 0.68,
        color: CupertinoColors.white,
      ),
    ),
  );
}

import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class UnreadBadge extends StatelessWidget {
  final int count;

  const UnreadBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CupertinoColors.destructiveRed,
        borderRadius: BorderRadius.circular(10),
        // Обводка фоном сервер-панели — чтобы бейдж визуально
        // отделялся от иконки сервера, а не сливался с ней по краю.
        border: Border.all(color: AppColors.mainBackground, width: 2),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppText.lowTextStyle.copyWith(
          color: CupertinoColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 9,
          height: 1,
        ),
      ),
    );
  }
}

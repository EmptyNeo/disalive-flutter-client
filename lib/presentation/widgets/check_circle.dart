import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class CheckCircle extends StatelessWidget {
  final bool isSelected;

  const CheckCircle({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.blurple : CupertinoColors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.blurple : AppColors.iconGrey,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(
              CupertinoIcons.check_mark,
              color: CupertinoColors.white,
              size: 14,
            )
          : null,
    );
  }
}

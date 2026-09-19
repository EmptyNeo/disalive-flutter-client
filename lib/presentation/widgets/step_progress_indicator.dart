import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class StepProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final double height;
  final double gap;
  final double borderRadius;

  const StepProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.height = 6.0,
    this.gap = 8.0,
    this.borderRadius = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final stepNumber = index + 1;
        final isCompleted = stepNumber < currentStep;
        final isCurrent = stepNumber == currentStep;

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: height,
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : gap),
            decoration: BoxDecoration(
              // 🎯 Логика цветов:
              // 1. Если шаг пройден -> сплошной цвет blurple
              // 2. Если текущий шаг -> прозрачный фон
              // 3. Если будущий шаг -> цвет divider (серый)
              color: isCompleted
                  ? AppColors.blurple
                  : (isCurrent
                        ? CupertinoColors.transparent
                        : AppColors.divider),
              borderRadius: BorderRadius.circular(borderRadius),
              // 🎯 Логика обводки: только для текущего шага
              border: isCurrent
                  ? Border.all(color: AppColors.blurple, width: 1.5)
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

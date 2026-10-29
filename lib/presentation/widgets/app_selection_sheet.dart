import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/utils/ui/emoji_text_parser.dart';
import 'package:flutter/cupertino.dart';

class AppSelectionOption<T> {
  const AppSelectionOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// Выбор одного значения в оформлении нижних шторок приложения.
class AppSelectionSheet<T> extends StatelessWidget {
  const AppSelectionSheet({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
  });

  final String title;
  final List<AppSelectionOption<T>> options;
  final T? selectedValue;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<AppSelectionOption<T>> options,
    T? selectedValue,
  }) => showCupertinoModalPopup<T>(
    context: context,
    builder: (_) => AppSelectionSheet<T>(
      title: title,
      options: options,
      selectedValue: selectedValue,
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.glassPanelTop, AppColors.glassPanelBottom],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.greyple.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.blurple,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: AppText.mediumTextStyle.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Icon(
                        CupertinoIcons.xmark,
                        color: AppColors.iconGrey,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Column(
                      children: [
                        for (final option in options)
                          _optionTile(context, option),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _optionTile(BuildContext context, AppSelectionOption<T> option) {
    final selected = option.value == selectedValue;
    final color = selected ? AppColors.blurple : AppColors.white;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      minimumSize: const Size(0, 48),
      onPressed: () => Navigator.of(context).pop(option.value),
      child: Row(
        children: [
          if (option.icon != null) ...[
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(option.icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text.rich(
              TextSpan(
                children: EmojiTextParser.parse(
                  option.label,
                  emojiSize: 18,
                  animateEmoji: false,
                ),
              ),
              style: AppText.mediumTextStyle.copyWith(color: AppColors.white),
            ),
          ),
          Icon(
            selected
                ? CupertinoIcons.check_mark_circled_solid
                : CupertinoIcons.circle,
            size: 22,
            color: selected ? AppColors.blurple : AppColors.greyple,
          ),
        ],
      ),
    );
  }
}

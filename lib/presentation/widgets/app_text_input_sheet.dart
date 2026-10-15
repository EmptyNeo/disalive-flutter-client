import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

/// Поле ввода в нижней шторке с оформлением приложения.
class AppTextInputSheet extends StatefulWidget {
  const AppTextInputSheet({
    super.key,
    required this.title,
    this.initialValue = '',
    this.placeholder = 'Название',
    this.actionLabel = 'Сохранить',
    this.maxLength = 30,
  });

  final String title;
  final String initialValue;
  final String placeholder;
  final String actionLabel;
  final int maxLength;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String initialValue = '',
    String placeholder = 'Название',
    String actionLabel = 'Сохранить',
    int maxLength = 30,
  }) => showCupertinoModalPopup<String>(
    context: context,
    builder: (_) => AppTextInputSheet(
      title: title,
      initialValue: initialValue,
      placeholder: placeholder,
      actionLabel: actionLabel,
      maxLength: maxLength,
    ),
  );

  @override
  State<AppTextInputSheet> createState() => _AppTextInputSheetState();
}

class _AppTextInputSheetState extends State<AppTextInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue)
      ..addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => AnimatedPadding(
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    padding: EdgeInsets.fromLTRB(
      12,
      0,
      12,
      MediaQuery.viewInsetsOf(context).bottom + 12,
    ),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.greyple.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
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
                        widget.title,
                        style: AppText.highTextStyle.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: 18,
                        color: AppColors.iconGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  key: const ValueKey('app_text_input_sheet_field'),
                  controller: _controller,
                  autofocus: true,
                  maxLength: widget.maxLength,
                  placeholder: widget.placeholder,
                  padding: const EdgeInsets.all(14),
                  style: TextStyle(color: AppColors.white),
                  placeholderStyle: TextStyle(color: AppColors.greyple),
                  decoration: BoxDecoration(
                    color: AppColors.actionGrey,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  key: const ValueKey('app_text_input_sheet_save'),
                  onPressed: _controller.text.trim().isEmpty ? null : _save,
                  child: Text(widget.actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

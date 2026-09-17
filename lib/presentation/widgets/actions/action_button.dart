import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class ActionButton extends StatelessWidget {
  final VoidCallback _onTap;
  final bool _canPress;
  final bool _isLoading;
  final String _title;

  const ActionButton({
    super.key,
    required VoidCallback onTap,
    required bool canPress,
    required bool isLoading,
    required String title,
  }) : _onTap = onTap,
       _canPress = canPress,
       _isLoading = isLoading,
       _title = title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GestureDetector(
        onTap: _canPress ? _onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _canPress
                ? AppColors.blurple
                : AppColors.blurple.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CupertinoActivityIndicator(
                    color: CupertinoColors.white,
                    radius: 11,
                  ),
                )
              : Text(
                  _title,
                  style: TextStyle(
                    color: AppColors.onBlurple,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

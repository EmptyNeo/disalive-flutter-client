import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/ui/error_config.dart';
import 'package:flutter/cupertino.dart';

class ErrorStateView extends StatelessWidget {
  final Failure failure;

  final VoidCallback? onRetry;

  const ErrorStateView({super.key, required this.failure, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final config = _getErrorConfig(failure);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: config.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(config.icon, size: 48, color: config.color),
            ),
            const SizedBox(height: 24),

            Text(
              failure.message,
              style: AppText.highTextStyle.copyWith(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 32),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onRetry,
                child: Text(
                  'Повторить',
                  style: AppText.mediumTextStyle.copyWith(
                    color: AppColors.linkBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ErrorConfig _getErrorConfig(Failure failure) {
    switch (failure.runtimeType) {
      case const (NetworkFailure):
        return const ErrorConfig(
          icon: CupertinoIcons.wifi_slash,
          color: AppColors.blurple,
        );
      case const (UnauthorizedFailure):
        return const ErrorConfig(
          icon: CupertinoIcons.lock_shield_fill,
          color: AppColors.errorRed,
        );
      case const (ServerFailure):
        return const ErrorConfig(
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          color: AppColors.errorRed,
        );
      case const (ParsingFailure):
        return const ErrorConfig(
          icon: CupertinoIcons.doc_chart_fill,
          color: AppColors.yellow,
        );
      case const (CacheFailure):
        return ErrorConfig(
          icon: CupertinoIcons.doc_on_doc_fill,
          color: AppColors.greyple,
        );
      case const (ValidationFailure):
        return const ErrorConfig(
          icon: CupertinoIcons.exclamationmark_circle_fill,
          color: AppColors.errorRed,
        );
      default:
        return ErrorConfig(
          icon: CupertinoIcons.info_circle_fill,
          color: AppColors.greyple,
        );
    }
  }
}

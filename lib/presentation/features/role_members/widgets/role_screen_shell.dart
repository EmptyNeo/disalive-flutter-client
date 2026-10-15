import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/widgets/actions/action_button.dart';
import 'package:disalive/presentation/widgets/actions/action_header.dart';
import 'package:flutter/cupertino.dart';

class RoleScreenShell extends StatelessWidget {
  const RoleScreenShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actionTitle,
    this.onAction,
    this.actionEnabled = true,
    this.actionLoading = false,
    this.titleSuffix,
  });

  final String title;
  final String subtitle;
  final Widget? titleSuffix;
  final Widget child;
  final String? actionTitle;
  final VoidCallback? onAction;
  final bool actionEnabled;
  final bool actionLoading;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.mainBackground,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.12),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      children: [
                        if (titleSuffix == null)
                          ActionHeader(title: title, subtitle: subtitle)
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (title.isNotEmpty) ...[
                                            Flexible(
                                              child: Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: AppColors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          titleSuffix!,
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          color: AppColors.greyple,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(32, 32),
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                  child: Icon(
                                    CupertinoIcons.xmark_circle_fill,
                                    color: AppColors.iconGrey,
                                    size: 26,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(child: child),
                        if (actionTitle != null) const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  if (actionTitle != null && onAction != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ActionButton(
                        onTap: onAction!,
                        canPress: actionEnabled,
                        isLoading: actionLoading,
                        title: actionTitle!,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

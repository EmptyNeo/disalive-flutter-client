import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class ActionHeader extends StatelessWidget {
  final String _title;
  final String? _subtitle;

  const ActionHeader({
    super.key,
    required String title,
    required String? subtitle,
  }) : _title = title,
       _subtitle = subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    style: TextStyle(
                      color: AppColors.greyple,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: AppColors.iconGrey,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

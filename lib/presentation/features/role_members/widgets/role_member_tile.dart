import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

class RoleMemberTile extends StatelessWidget {
  const RoleMemberTile({
    super.key,
    required this.member,
    this.selected,
    this.onTap,
    this.onRemove,
  });

  final Member member;
  final bool? selected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final user = member.user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                onPressed: onTap,
                child: Row(
                  children: [
                    BuildAvatar(
                      url: user?.urlAvatar ?? '',
                      wh: 34,
                      size: 20,
                      status: user?.status,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        user?.getDisplayName ?? 'Участник',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.white, fontSize: 15),
                      ),
                    ),
                    if (selected != null)
                      Icon(
                        selected!
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        color: selected!
                            ? AppColors.blurple
                            : AppColors.greyple,
                        size: 23,
                      ),
                  ],
                ),
              ),
            ),
            if (onRemove != null)
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                onPressed: onRemove,
                child: Icon(
                  CupertinoIcons.minus_circle,
                  color: AppColors.errorRed,
                  size: 21,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

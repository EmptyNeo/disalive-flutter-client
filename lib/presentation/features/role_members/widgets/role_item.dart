import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_emoji.dart';
import 'package:flutter/cupertino.dart';

class RoleItem extends StatelessWidget {
  const RoleItem({
    super.key,
    required this.role,
    required this.onTap,
    required this.onDelete,
  });

  final RoleMember role;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                onPressed: onTap,
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.shield_lefthalf_fill,
                      size: 21,
                      color: AppColors.iconGrey,
                    ),
                    const SizedBox(width: 11),
                    if (role.name?.trim().isNotEmpty == true)
                      Flexible(
                        child: Text(
                          role.name!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (role.emoji?.isNotEmpty == true) ...[
                      if (role.name?.trim().isNotEmpty == true)
                        const SizedBox(width: 7),
                      RoleEmoji(role.emoji),
                    ],
                  ],
                ),
              ),
            ),
            CupertinoButton(
              key: ValueKey('delete_role_${role.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onPressed: onDelete,
              child: Icon(
                CupertinoIcons.xmark,
                size: 19,
                color: AppColors.errorRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/features/role_members/role_permission_meta.dart';
import 'package:flutter/cupertino.dart';

class RolePermissionTile extends StatelessWidget {
  const RolePermissionTile({
    super.key,
    required this.meta,
    required this.value,
    required this.onChanged,
  });

  final RolePermissionMeta meta;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.lightGrey,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meta.label,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                meta.description,
                style: TextStyle(color: AppColors.greyple, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CupertinoSwitch(
          value: value,
          activeTrackColor: AppColors.blurple,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

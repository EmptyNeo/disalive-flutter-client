import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_emoji.dart';
import 'package:flutter/cupertino.dart';

class ServerMainRoleSheet extends StatelessWidget {
  const ServerMainRoleSheet({
    super.key,
    required this.roles,
    required this.selectedRoleId,
  });

  final List<RoleMember> roles;
  final int? selectedRoleId;

  /// 0 means that the server has no main role; null means the sheet was closed.
  static Future<int?> show(
    BuildContext context, {
    required List<RoleMember> roles,
    required int? selectedRoleId,
  }) => showCupertinoModalPopup<int>(
    context: context,
    builder: (_) =>
        ServerMainRoleSheet(roles: roles, selectedRoleId: selectedRoleId),
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
          border: Border.all(color: AppColors.divider),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Основная роль',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
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
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  children: [
                    _tile(context, null),
                    for (final role in roles)
                      if (role.id != null) _tile(context, role),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _tile(BuildContext context, RoleMember? role) {
    final selected = role?.id == selectedRoleId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(17),
        ),
        child: CupertinoButton(
          key: ValueKey(
            role == null ? 'main_role_none' : 'main_role_${role.id}',
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          onPressed: () => Navigator.of(context).pop(role?.id ?? 0),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.shield_lefthalf_fill,
                color: AppColors.iconGrey,
                size: 21,
              ),
              const SizedBox(width: 11),
              if (role == null)
                Expanded(
                  child: Text(
                    'Без основной роли',
                    style: TextStyle(color: AppColors.white),
                  ),
                )
              else ...[
                if (role.name?.trim().isNotEmpty == true)
                  Flexible(
                    child: Text(
                      role.name!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.white, fontSize: 15),
                    ),
                  ),
                if (role.emoji?.isNotEmpty == true) ...[
                  if (role.name?.trim().isNotEmpty == true)
                    const SizedBox(width: 7),
                  RoleEmoji(role.emoji),
                ],
              ],
              const Spacer(),
              Icon(
                selected
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                color: selected ? AppColors.blurple : AppColors.greyple,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

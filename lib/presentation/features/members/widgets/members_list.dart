// presentation/features/members/widgets/members_list.dart
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/members/moderation/entity_moderation_screen.dart';
import 'package:disalive/presentation/features/members/moderation/member_moderation_screen.dart';
import 'package:disalive/presentation/features/members/member_item.dart';
import 'package:disalive/presentation/features/role_members/role_members_screen.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_emoji.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Виджет, отображающий заголовок секции и список участников чата/сервера.
/// Является Sliver-виджетом и должен использоваться напрямую внутри CustomScrollView.
class MembersList extends StatelessWidget {
  final int entityId;
  final EntityType entityType;
  final String entityName;
  final int? initialMemberCount;
  final bool canManageMembers;
  final bool canManageRoles;
  final bool canReorderRoles;

  const MembersList({
    super.key,
    required this.entityId,
    required this.entityType,
    required this.entityName,
    this.initialMemberCount,
    this.canManageMembers = false,
    this.canManageRoles = false,
    this.canReorderRoles = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MembersBloc, MembersState>(
      builder: (context, state) {
        int count = initialMemberCount ?? 0;
        List<Member> members = [];
        final loaded =
            state is MembersLoaded &&
                state.entityId == entityId &&
                state.entityType == entityType
            ? state
            : null;

        if (loaded != null) {
          count = loaded.memberCount > 0
              ? loaded.memberCount
              : loaded.members.length;
          members = loaded.members;
        }

        return SliverMainAxisGroup(
          slivers: [
            // 🎯 Заголовок секции (как Sliver)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Участники - $count',
                        style: AppText.lowTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.greyple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (canManageMembers)
                      CupertinoButton(
                        key: const ValueKey('entity_moderation_button'),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        onPressed: () => EntityModerationScreen.open(
                          context,
                          entityId: entityId,
                          entityType: entityType,
                          entityName: entityName,
                        ),
                        child: const Text('Ограничения'),
                      ),
                  ],
                ),
              ),
            ),

            // 🎯 Контент в зависимости от состояния (центрируется на весь оставшийся экран)
            if (state is MembersLoading ||
                state is MembersInitial ||
                (state is MembersLoaded && loaded == null))
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CupertinoActivityIndicator()),
              )
            else if (state is MembersFailure)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: AppText.mediumTextStyle.copyWith(
                        color: AppColors.greyple,
                      ),
                    ),
                  ),
                ),
              )
            else if (loaded != null && members.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Пока нет участников',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.greyple),
                    ),
                  ),
                ),
              )
            else if (loaded != null)
              ..._buildRoleGroupedSlivers(members),
          ],
        );
      },
    );
  }

  List<Widget> _buildRoleGroupedSlivers(List<Member> members) {
    final groupsByKey = <String, _MemberRoleGroup>{};
    for (final member in members) {
      final role = member.role;
      final roleId = role?.id ?? member.fkRole;
      final key = roleId == null ? 'unassigned' : 'role:$roleId';
      final group = groupsByKey.putIfAbsent(
        key,
        () => _MemberRoleGroup(role: role, sortOrder: role?.sortOrder ?? 0),
      );
      group.members.add(member);
    }
    final groups = groupsByKey.values.toList()
      ..sort((a, b) {
        if (a.role == null && b.role != null) return 1;
        if (a.role != null && b.role == null) return -1;
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return (a.role?.id ?? 0).compareTo(b.role?.id ?? 0);
      });

    return [
      for (final group in groups) ...[
        SliverToBoxAdapter(child: _MemberRoleHeader(group: group)),
        SliverList.builder(
          itemCount: group.members.length,
          itemBuilder: (context, index) {
            final member = group.members[index];
            return MemberItem(
              key: ValueKey(member.fkUser),
              member: member,
              onLongPress: () => _showMemberActions(context, member),
            );
          },
        ),
      ],
    ];
  }

  void removeMember(BuildContext context, Member member) async {
    final entityKey = EntityKey(entityId: entityId, entityType: entityType);
    final result =
        await showConfirmationDialog(
          context,
          title: "Исключить участника",
          description:
              "Вы уверены, что хотите исключить ${member.user?.getDisplayName}",
        ) ??
        false;
    if (result) {
      sl<MembersRepository>().remove(entityKey, member.user?.getId ?? 0);
    }
  }

  Future<void> _unmuteMember(BuildContext context, Member member) async {
    final userId = member.fkUser;
    if (userId == null) return;
    final result = await sl<MembersRepository>().moderate(
      entityKey: EntityKey(entityId: entityId, entityType: entityType),
      userId: userId,
      action: 'unmute',
    );
    if (!context.mounted) return;
    result.fold(
      (failure) => CustomToast.open(context: context, message: failure.message),
      (_) => CustomToast.open(
        context: context,
        message: 'Оглушение снято',
        color: AppColors.successGreen,
        icon: CupertinoIcons.checkmark_circle_fill,
      ),
    );
  }

  void _showMemberActions(BuildContext context, Member member) {
    final isSelf = member.isSelf ?? false;

    if (!canManageRoles && !canManageMembers) {
      return;
    }

    final actions = <ActionItem>[
      if (canManageRoles)
        ActionItem(
          icon: CupertinoIcons.shield_fill,
          label: 'Управление ролью',
          onTap: () => RoleMembersScreen.open(
            context,
            entityId: entityId,
            entityType: entityType,
            entityName: entityName,
            canReorderRoles: canReorderRoles,
          ),
        ),

      if (!isSelf && !member.isChatOwner && canManageMembers)
        ActionItem(
          icon: CupertinoIcons.chat_bubble_text,
          label: member.isChatMuted == true ? 'Размутить' : 'Обезмолвить',
          onTap: () => member.isChatMuted == true
              ? _unmuteMember(context, member)
              : MemberModerationScreen.open(
                  context,
                  entityId: entityId,
                  entityType: entityType,
                  entityName: entityName,
                  member: member,
                  action: 'mute',
                ),
        ),
      if (!isSelf && !member.isChatOwner && canManageMembers)
        ActionItem(
          icon: CupertinoIcons.hand_raised_fill,
          label: 'Заблокировать',
          isDestructive: true,
          onTap: () => MemberModerationScreen.open(
            context,
            entityId: entityId,
            entityType: entityType,
            entityName: entityName,
            member: member,
            action: 'ban',
          ),
        ),

      if (!isSelf && canManageMembers)
        ActionItem(
          icon: CupertinoIcons.person_crop_circle_badge_minus,
          label: entityType == EntityType.server
              ? 'Исключить с сервера'
              : 'Выгнать из группы',
          isDestructive: true,
          onTap: () {
            removeMember(context, member);
          },
        ),
    ];

    ActionBottomSheet.show(
      context,
      title: member.user?.getDisplayName,
      actions: actions,
    );
  }
}

class _MemberRoleGroup {
  _MemberRoleGroup({required this.role, required this.sortOrder});

  final RoleMember? role;
  final int sortOrder;
  final List<Member> members = [];
}

class _MemberRoleHeader extends StatelessWidget {
  const _MemberRoleHeader({required this.group});

  final _MemberRoleGroup group;

  @override
  Widget build(BuildContext context) {
    final roleName = group.role?.name?.trim();
    final title = roleName?.isNotEmpty == true ? roleName! : 'УЧАСТНИК';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 7),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.lowTextStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.greyple,
                      letterSpacing: 0.35,
                    ),
                  ),
                ),
                if ((group.role?.emoji ?? '').isNotEmpty) ...[
                  const SizedBox(width: 5),
                  RoleEmoji(group.role!.emoji, size: 15),
                ],
              ],
            ),
          ),
          Text(
            '${group.members.length}',
            style: AppText.lowTextStyle.copyWith(color: AppColors.greyple),
          ),
        ],
      ),
    );
  }
}

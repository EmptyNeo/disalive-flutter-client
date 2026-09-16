// presentation/features/members/widgets/members_list.dart
import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/permissions.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/services/determining_context_service.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/members/member_item.dart';
import 'package:disalive/presentation/features/profile/user_profile_screen.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Виджет, отображающий заголовок секции и список участников чата/сервера.
/// Является Sliver-виджетом и должен использоваться напрямую внутри CustomScrollView.
class MembersList extends StatelessWidget {
  final Chat chat;

  const MembersList({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MembersBloc, MembersState>(
      builder: (context, state) {
        int count = chat.memberCount ?? 0;
        List<Member> members = [];

        if (state is MembersLoaded) {
          count = state.memberCount > 0
              ? state.memberCount
              : state.members.length;
          members = state.members;
        }

        return SliverMainAxisGroup(
          slivers: [
            // 🎯 Заголовок секции (как Sliver)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Участники - $count',
                  style: AppText.lowTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.greyple,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // 🎯 Контент в зависимости от состояния (центрируется на весь оставшийся экран)
            if (state is MembersLoading)
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
            else if (state is MembersLoaded && members.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'В группе пока нет участников',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.greyple),
                    ),
                  ),
                ),
              )
            else if (state is MembersLoaded)
              // Использование SliverList вместо ListView.builder убирает проблему с shrinkWrap
              SliverList.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return MemberItem(
                    key: ValueKey(member.fkUser),
                    member: member,
                    onLongPress: () => _showMemberActions(context, member),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  void removeMember(BuildContext context, Member member) async {
    final entityKey = DeterminingContextService.getEntityKey();
    if (entityKey == null) {
      return;
    }
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

  void _showMemberActions(BuildContext context, Member member) {
    final isSelf = member.isSelf ?? false;

    if (chat.role == null) {
      return;
    }

    final hasManageMembers = chat.role?.hasPermission(
      GeneralPermissions.manageMembers,
    );
    final hasManageRoles = chat.role?.hasPermission(
      GeneralPermissions.manageRoles,
    );

    if (hasManageRoles == false && hasManageMembers == false) {
      return;
    }

    final actions = <ActionItem>[
      if (hasManageRoles == true)
        ActionItem(
          icon: CupertinoIcons.shield_fill,
          label: 'Управление ролью',
          onTap: () {},
        ),

      if (!isSelf && hasManageMembers == true)
        ActionItem(
          icon: CupertinoIcons.person_crop_circle_badge_minus,
          label: 'Выгнать из группы',
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

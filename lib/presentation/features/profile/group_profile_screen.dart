import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/media_filter_item.dart';
import 'package:disalive/domain/models/permissions.dart';
import 'package:disalive/presentation/features/chat/screens/add_members_screen.dart';
import 'package:disalive/presentation/features/home/screens/edit_group_screen.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/members/widgets/members_list.dart';
import 'package:disalive/presentation/features/profile/widgets/profile_vertical_action_tile.dart';
import 'package:disalive/presentation/features/profile/widgets/media_stats_section.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/custom_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupProfileScreen extends StatefulWidget {
  final Chat chat;
  final ValueChanged<MediaStatsCategory>? onMediaCategoryTap;
  final ValueChanged<MediaFilterMutualGroup>? onGroupTap;
  final ValueChanged<int>? onMessageTap;

  const GroupProfileScreen({
    super.key,
    required this.chat,
    this.onMediaCategoryTap,
    this.onGroupTap,
    this.onMessageTap,
  });

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  late final MembersBloc _membersBloc;

  @override
  void initState() {
    super.initState();
    _membersBloc = context.read<MembersBloc>();

    _membersBloc.add(
      GetMembers(entityId: widget.chat.id, entityType: EntityType.chat),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.mainBackground,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [_buildUnifiedList(), const CustomBackButton()],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedList() {
    bool manageMembers =
        widget.chat.role?.hasPermission(ChatPermissions.manageMembers) ?? false;
    bool manageChat =
        widget.chat.role?.hasPermission(ChatPermissions.manageChat) ?? false;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 24),
            child: Column(
              children: [
                BuildAvatar(
                  url: widget.chat.urlAvatar,
                  wh: 80,
                  size: 45,
                  isBookmark: false,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.chat.name,
                    style: AppText.highTextStyle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (manageChat || manageMembers) ...[
                  Padding(
                    padding: EdgeInsets.only(
                      right: 12,
                      left: 12,
                      top: 12,
                      bottom: 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (manageMembers) ...[
                          ProfileVerticalActionTile(
                            icon: CupertinoIcons.person_2_fill,
                            title: 'Добавить',
                            onTap: () {
                              AddMembersScreen.open(context, widget.chat);
                            },
                          ),
                        ],
                        SizedBox(width: 8),
                        if (manageChat) ...[
                          ProfileVerticalActionTile(
                            icon: CupertinoIcons.pencil,
                            title: 'Редактировать',
                            onTap: () {
                              EditGroupScreen.open(context, widget.chat);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: MediaStatsSection(
              chatId: widget.chat.id,
              onCategoryTap: widget.onMediaCategoryTap,
              onMessageTap: widget.onMessageTap,
              onGroupTap: widget.onGroupTap,
            ),
          ),
        ),
        MembersList(
          entityId: widget.chat.id,
          entityType: EntityType.chat,
          entityName: widget.chat.name,
          initialMemberCount: widget.chat.memberCount,
          canManageMembers: manageMembers,
          canManageRoles:
              widget.chat.role?.hasPermission(ChatPermissions.manageRoles) ??
              false,
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

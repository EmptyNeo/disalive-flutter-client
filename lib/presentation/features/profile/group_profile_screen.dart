import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/media_filter_item.dart';
import 'package:disalive/domain/models/permissions.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat/screens/add_members_screen.dart';
import 'package:disalive/presentation/features/home/screens/edit_group_screen.dart';
import 'package:disalive/presentation/features/invites/invite_server_screen.dart';
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
                children: [
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      final updated = state is ChatLoaded
                          ? state.chats.where(
                              (chat) => chat.id == widget.chat.id,
                            )
                          : <Chat>[];
                      return _buildUnifiedList(
                        updated.isEmpty ? widget.chat : updated.first,
                      );
                    },
                  ),
                  const CustomBackButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedList(Chat chat) {
    bool manageMembers =
        chat.role?.hasPermission(ChatPermissions.manageMembers) ?? false;
    bool manageChat =
        chat.role?.hasPermission(ChatPermissions.manageChat) ?? false;
    final canInvite =
        chat.isOwner ||
        chat.role?.hasPermission(ChatPermissions.manageInvites) == true ||
        chat.member?.role?.hasPermission(ChatPermissions.manageInvites) == true;
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
                    chat.name,
                    style: AppText.highTextStyle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (manageChat || manageMembers || canInvite) ...[
                  Padding(
                    padding: EdgeInsets.only(
                      right: 12,
                      left: 12,
                      top: 12,
                      bottom: 0,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        if (manageMembers) ...[
                          ProfileVerticalActionTile(
                            icon: CupertinoIcons.person_2_fill,
                            title: 'Добавить',
                            onTap: () {
                              AddMembersScreen.open(context, chat);
                            },
                          ),
                        ],
                        if (canInvite)
                          ProfileVerticalActionTile(
                            icon: CupertinoIcons.person_add,
                            title: 'Пригласить',
                            onTap: () => InviteServerScreen.openChat(
                              context,
                              chat: chat,
                            ),
                          ),
                        if (manageChat) ...[
                          ProfileVerticalActionTile(
                            icon: CupertinoIcons.pencil,
                            title: 'Редактировать',
                            onTap: () {
                              EditGroupScreen.open(context, chat);
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
              chatId: chat.id,
              onCategoryTap: widget.onMediaCategoryTap,
              onMessageTap: widget.onMessageTap,
              onGroupTap: widget.onGroupTap,
            ),
          ),
        ),
        MembersList(
          entityId: chat.id,
          entityType: EntityType.chat,
          entityName: chat.name,
          initialMemberCount: chat.memberCount,
          canManageMembers: manageMembers,
          canManageRoles:
              chat.role?.hasPermission(ChatPermissions.manageRoles) ?? false,
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

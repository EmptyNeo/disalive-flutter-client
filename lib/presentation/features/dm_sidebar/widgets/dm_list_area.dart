import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/permissions.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/repositories/friends_repository.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/presentation/features/chat/widgets/chat_item.dart';
import 'package:disalive/presentation/features/home/screens/edit_group_screen.dart';
import 'package:disalive/presentation/features/role_members/role_members_screen.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:flutter/cupertino.dart';

class DmListArea extends StatelessWidget {
  final List<Chat> chats;
  final bool isLoading;
  final bool isSearchActive;
  final bool isReconnect;

  const DmListArea({
    super.key,
    required this.chats,
    required this.isReconnect,
    this.isLoading = false,
    this.isSearchActive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (chats.isEmpty) {
      return Center(
        child: Text(
          isSearchActive ? 'Ничего не найдено' : 'У вас пока нет чатов',
          style: TextStyle(color: AppColors.white.withValues(alpha: 0.3)),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(
        bottom: 100, // Отступ под нижнее меню
      ),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        Chat chat = chats[index];
        return ChatItem(
          chat: chat,
          onLongPress: () => _showChatActions(context, chat),
          isReconnect: isReconnect,
        );
      },
    );
  }

  void _togglePinned(Chat chat) {
    sl<MembersRepository>().update(
      entityId: chat.id,
      entityType: EntityType.chat,
      toggleFixed: true,
    );
  }

  void _toggleMuted(Chat chat) {
    sl<MembersRepository>().update(
      entityId: chat.id,
      entityType: EntityType.chat,
      toggleMuted: true,
    );
  }

  void _toggleBlock(Chat chat) {
    sl<FriendsRepository>().toggleBlock(chat.id);
  }

  void _deleteFriend(BuildContext context, Chat chat) async {
    String displayName = chat.user?.displayName ?? '';
    final confirmed = await showConfirmationDialog(
      context,
      title: "Удалить из друзей",
      description: "Вы уверены, что хотите удалить из друзей $displayName?",
    );

    if (confirmed == true) {
      sl<FriendsRepository>().delete(chat.id);
    }
  }

  void _leaveFromGroup(BuildContext context, Chat chat) async {
    String displayName = chat.name;

    final confirmed = await showConfirmationDialog(
      context,
      title: "Покинуть группу",
      description: "Вы уверены, что хотите покинуть группу $displayName?",
    );
    if (confirmed == true) {
      sl<MembersRepository>().leave(chat.id, EntityType.chat);
    }
  }

  void _showChatActions(BuildContext context, Chat chat) {
    Member? member = chat.member;
    RoleMember? role = chat.role;
    if (member == null) return;

    final actions = <ActionItem>[
      ActionItem(
        icon: member.isFixed
            ? CupertinoIcons.pin_slash_fill
            : CupertinoIcons.pin_fill,
        label: member.isFixed ? "Открепить" : "Закрепить",
        onTap: () => _togglePinned(chat),
      ),
      if (!chat.isSolo) ...[
        ActionItem(
          icon: member.isMuted
              ? CupertinoIcons.bell_fill
              : CupertinoIcons.bell_slash_fill,
          label: member.isMuted
              ? "Включить уведомления"
              : "Выключить уведомления",
          onTap: () => _toggleMuted(chat),
        ),
      ],
      if (chat.isPersonalChat) ...[
        ActionItem(
          icon: CupertinoIcons.person_badge_minus_fill,
          label: "Удалить из друзей",
          isDestructive: true,
          onTap: () => _deleteFriend(context, chat),
        ),
        ActionItem(
          icon:
              chat.user?.onlyIBlocked == true || chat.user?.bothBlocked == true
              ? CupertinoIcons.lock_slash_fill
              : CupertinoIcons.lock_fill,
          label:
              chat.user?.onlyIBlocked == true || chat.user?.bothBlocked == true
              ? "Разблокировать"
              : "Заблокировать",
          isDestructive: true,
          onTap: () => _toggleBlock(chat),
        ),
      ],
      if (chat.isGroup) ...[
        if (chat.isOwner ||
            (role?.hasPermission(ChatPermissions.manageRoles) ?? false))
          ActionItem(
            icon: CupertinoIcons.shield_lefthalf_fill,
            label: 'Управление ролями',
            onTap: () => RoleMembersScreen.open(
              context,
              entityId: chat.id,
              entityType: EntityType.chat,
              entityName: chat.name,
            ),
          ),
        if (role != null && role.hasPermission(ChatPermissions.manageChat)) ...[
          ActionItem(
            icon: CupertinoIcons.pencil,
            label: "Редактировать группу",
            onTap: () => EditGroupScreen.open(context, chat),
          ),
        ],
        ActionItem(
          icon: CupertinoIcons.person_badge_minus_fill,
          label: "Покинуть группу",
          isDestructive: true,
          onTap: () => _leaveFromGroup(context, chat),
        ),
      ],
    ];

    ActionBottomSheet.show(context, title: chat.name, actions: actions);
  }
}

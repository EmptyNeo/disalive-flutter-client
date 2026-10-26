import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/role_member.dart';
import 'package:disalive/domain/repositories/channel_server_repository.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/domain/repositories/role_member_repository.dart';
import 'package:disalive/presentation/features/channel_server/bloc/channel_server_bloc.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_emoji.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_member_tile.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_screen_shell.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_search_field.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';

class ChannelAccessScreen extends StatefulWidget {
  const ChannelAccessScreen({
    super.key,
    required this.serverId,
    required this.serverName,
    required this.name,
    required this.type,
    required this.categoryId,
    this.maxParticipants,
    required this.channelsBloc,
  });

  final int serverId;
  final String serverName;
  final String name;
  final String type;
  final int? categoryId;
  final int? maxParticipants;
  final ChannelServerBloc channelsBloc;

  static Future<bool> open(
    BuildContext context, {
    required int serverId,
    required String serverName,
    required String name,
    required String type,
    required int? categoryId,
    int? maxParticipants,
    required ChannelServerBloc channelsBloc,
  }) async {
    return await SwipeToDismissRoute.push<bool>(
          context,
          (_) => ChannelAccessScreen(
            serverId: serverId,
            serverName: serverName,
            name: name,
            type: type,
            categoryId: categoryId,
            maxParticipants: maxParticipants,
            channelsBloc: channelsBloc,
          ),
        ) ??
        false;
  }

  @override
  State<ChannelAccessScreen> createState() => _ChannelAccessScreenState();
}

class _ChannelAccessScreenState extends State<ChannelAccessScreen> {
  List<RoleMember> _roles = const [];
  List<Member> _members = const [];
  final Set<int> _selectedRoles = {};
  final Set<int> _selectedUsers = {};
  String _query = '';
  String? _loadError;
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final rolesFuture = sl<RoleMemberRepository>().get(
      widget.serverId,
      EntityType.server,
    );
    final membersFuture = sl<MembersRepository>().get(
      widget.serverId,
      EntityType.server,
    );
    final rolesResult = await rolesFuture;
    final membersResult = await membersFuture;
    if (!mounted) return;
    rolesResult.fold(
      (failure) => _loadError = failure.message,
      (roles) => _roles = roles,
    );
    membersResult.fold(
      (failure) => _loadError ??= failure.message,
      (members) => _members = members,
    );
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    if (_creating || _loading || _loadError != null) return;
    setState(() => _creating = true);
    final result = await sl<ChannelServerRepository>().create(
      widget.serverId,
      widget.name,
      type: widget.type,
      categoryId: widget.categoryId,
      maxParticipants: widget.maxParticipants,
      isPrivate: true,
      userIds: _selectedUsers.toList(),
      roleIds: _selectedRoles.toList(),
    );
    if (!mounted) return;
    setState(() => _creating = false);
    result.fold(
      (failure) => CustomToast.open(context: context, message: failure.message),
      (channel) {
        widget.channelsBloc.add(
          ServerChannelUpserted(widget.serverId, channel.toMap()),
        );
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final roles = _roles.where((role) {
      final text = '${role.name ?? ''} ${role.emoji ?? ''}'.toLowerCase();
      return role.id != null && text.contains(_query);
    }).toList();
    final members = _members.where((member) {
      final user = member.user;
      final text = '${user?.getDisplayName ?? ''} ${user?.username ?? ''}'
          .toLowerCase();
      return member.fkUser != null && text.contains(_query);
    }).toList();

    return RoleScreenShell(
      title: 'Добавить участников или роли',
      subtitle: '${widget.serverName} · ${widget.name}',
      actionTitle: 'Создать',
      onAction: _create,
      actionEnabled: !_creating && !_loading && _loadError == null,
      actionLoading: _creating,
      child: Column(
        children: [
          RoleSearchField(
            placeholder: 'Поиск ролей и участников',
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CupertinoActivityIndicator())
                : _loadError != null
                ? Center(
                    child: CupertinoButton(
                      onPressed: _load,
                      child: Text('$_loadError · Повторить'),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      _heading('Роли'),
                      if (roles.isEmpty) _empty('Роли не найдены'),
                      for (final role in roles) _roleTile(role),
                      _heading('Участники'),
                      if (members.isEmpty) _empty('Участники не найдены'),
                      for (final member in members)
                        RoleMemberTile(
                          member: member,
                          selected: _selectedUsers.contains(member.fkUser),
                          onTap: () => setState(() {
                            if (!_selectedUsers.add(member.fkUser!)) {
                              _selectedUsers.remove(member.fkUser);
                            }
                          }),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
    child: Text(
      title,
      style: TextStyle(color: AppColors.greyple, fontSize: 13),
    ),
  );

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
    child: Text(text, style: TextStyle(color: AppColors.greyple)),
  );

  Widget _roleTile(RoleMember role) {
    final selected = _selectedRoles.contains(role.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: CupertinoButton(
        key: ValueKey('channel_access_role_${role.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
        onPressed: () => setState(() {
          if (!_selectedRoles.add(role.id!)) _selectedRoles.remove(role.id);
        }),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.shield_lefthalf_fill,
              color: AppColors.iconGrey,
            ),
            const SizedBox(width: 10),
            if (role.name?.trim().isNotEmpty == true)
              Flexible(
                child: Text(
                  role.name!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            if (role.emoji?.isNotEmpty == true) ...[
              if (role.name?.trim().isNotEmpty == true)
                const SizedBox(width: 6),
              RoleEmoji(role.emoji),
            ],
            const Spacer(),
            Icon(
              selected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: selected ? AppColors.blurple : AppColors.greyple,
            ),
          ],
        ),
      ),
    );
  }
}

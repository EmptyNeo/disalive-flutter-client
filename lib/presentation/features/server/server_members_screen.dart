import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/permissions.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/members/widgets/members_list.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_screen_shell.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServerMembersScreen extends StatefulWidget {
  const ServerMembersScreen({super.key, required this.server});

  final Server server;

  static Future<void> open(BuildContext context, {required Server server}) {
    final membersBloc = context.read<MembersBloc>();
    return SwipeToDismissRoute.push(
      context,
      (_) => BlocProvider.value(
        value: membersBloc,
        child: ServerMembersScreen(server: server),
      ),
    );
  }

  @override
  State<ServerMembersScreen> createState() => _ServerMembersScreenState();
}

class _ServerMembersScreenState extends State<ServerMembersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MembersBloc>().add(
      GetMembers(entityId: widget.server.id!, entityType: EntityType.server),
    );
  }

  @override
  Widget build(BuildContext context) => RoleScreenShell(
    title: 'Участники',
    subtitle: widget.server.name ?? 'Сервер',
    child: CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        MembersList(
          entityId: widget.server.id!,
          entityType: EntityType.server,
          entityName: widget.server.name ?? 'Сервер',
          initialMemberCount: widget.server.memberCount,
          canManageMembers:
              widget.server.isServerOwner ||
              widget.server.hasPermission(ServerPermissions.manageMembers),
          canManageRoles:
              widget.server.isServerOwner ||
              widget.server.hasPermission(ServerPermissions.manageRoles),
        ),
      ],
    ),
  );
}

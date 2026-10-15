import 'package:disalive/domain/models/permissions.dart';
import 'package:disalive/domain/models/server.dart';

class ServerActionPermissions {
  final bool canInvite;
  final bool canManageServer;
  final bool canManageChannels;
  final bool canManageCategories;
  final bool canManageRoles;
  final bool canManageMembers;
  final bool canManageInvites;

  bool get canOpenSettings =>
      canManageServer || canManageRoles || canManageMembers || canManageInvites;

  const ServerActionPermissions._({
    required this.canInvite,
    required this.canManageServer,
    required this.canManageChannels,
    required this.canManageCategories,
    required this.canManageRoles,
    required this.canManageMembers,
    required this.canManageInvites,
  });

  factory ServerActionPermissions.fromServer(Server server) {
    final isOwner = server.isServerOwner;
    return ServerActionPermissions._(
      canInvite:
          isOwner ||
          server.canInviteUsers ||
          server.hasPermission(ServerPermissions.manageInvites),
      canManageServer:
          isOwner || server.hasPermission(ServerPermissions.manageServer),
      canManageChannels:
          isOwner || server.hasPermission(ServerPermissions.manageChannels),
      canManageCategories:
          isOwner || server.hasPermission(ServerPermissions.manageCategories),
      canManageRoles:
          isOwner || server.hasPermission(ServerPermissions.manageRoles),
      canManageMembers:
          isOwner || server.hasPermission(ServerPermissions.manageMembers),
      canManageInvites:
          isOwner || server.hasPermission(ServerPermissions.manageInvites),
    );
  }
}

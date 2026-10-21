import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/server.dart';

bool canSendToChannel({
  required ChannelServer? channel,
  required Server? server,
  required int? userId,
  required int? roleId,
}) {
  if (channel == null) return false;
  if (!channel.isPrivate) return true;
  if (server?.isOwner == true ||
      (userId != null && server?.fkOwner == userId)) {
    return true;
  }
  if (userId != null && channel.allowedUsers.contains(userId)) return true;
  return roleId != null && channel.allowedRoles.contains(roleId);
}

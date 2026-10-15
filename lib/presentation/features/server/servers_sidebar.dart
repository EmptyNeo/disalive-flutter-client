import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/server/widgets/server_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServersSidebar extends StatelessWidget {
  final int personalUnreadCount;
  final int? selectedServerId;
  final VoidCallback? onSelectDm;
  final ValueChanged<Server>? onSelectServer;
  final VoidCallback? onCreateServer;

  const ServersSidebar({
    super.key,
    required this.personalUnreadCount,
    this.selectedServerId,
    this.onSelectDm,
    this.onSelectServer,
    this.onCreateServer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: AppColors.mainBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            ServerItem(
              key: const ValueKey('dm_server_item'),
              icon: CupertinoIcons.chat_bubble_fill,
              isActive: selectedServerId == null,
              isSpecial: true,
              isAction: true,
              unreadCount: personalUnreadCount,
              onTap: onSelectDm,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 2,
                color: CupertinoColors.white.withValues(alpha: 0.1),
              ),
            ),
            ServerItem(
              icon: CupertinoIcons.add,
              isActive: false,
              isAction: true,
              unreadCount: 0,
              onTap: onCreateServer,
            ),
            Expanded(
              child: BlocBuilder<ServersBloc, ServersState>(
                builder: (context, state) {
                  if (state is ServersLoading || state is ServersInitial) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  if (state is ServersFailure) {
                    return Center(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            context.read<ServersBloc>().add(const GetServers()),
                        child: const Icon(CupertinoIcons.refresh),
                      ),
                    );
                  }
                  if (state is ServersLoaded) {
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: state.servers.length,
                      itemBuilder: (context, index) {
                        final server = state.servers[index];
                        return Padding(
                          key: ValueKey(server.id),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ServerItem(
                            icon: CupertinoIcons.group_solid,
                            name: server.name,
                            pathAvatar: server.pathAvatar,
                            isActive: selectedServerId == server.id,
                            unreadCount: server.newMessagesCount ?? 0,
                            onTap: () => onSelectServer?.call(server),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

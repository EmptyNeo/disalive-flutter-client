import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/server/widgets/server_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class ServersSidebar extends StatelessWidget {
  final int personalUnreadCount;
  final int? selectedServerId;
  final VoidCallback? onSelectDm;
  final ValueChanged<Server>? onSelectServer;
  final VoidCallback? onCreateServer;
  final VoidCallback? onDiscoverServers;
  final bool isDiscovering;

  const ServersSidebar({
    super.key,
    required this.personalUnreadCount,
    this.selectedServerId,
    this.onSelectDm,
    this.onSelectServer,
    this.onCreateServer,
    this.onDiscoverServers,
    this.isDiscovering = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: AppColors.mainBackground,
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<ServersBloc, ServersState>(
          builder: (context, state) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    ServerItem(
                      key: const ValueKey('dm_server_item'),
                      icon: CupertinoIcons.chat_bubble_fill,
                      isActive: selectedServerId == null && !isDiscovering,
                      isSpecial: true,
                      isAction: true,
                      unreadCount: personalUnreadCount,
                      onTap: onSelectDm,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                    const SizedBox(height: 12),
                    ServerItem(
                      key: const ValueKey('discover_servers_item'),
                      icon: CupertinoIcons.compass_fill,
                      isActive: isDiscovering,
                      isAction: true,
                      unreadCount: 0,
                      onTap: onDiscoverServers,
                    ),
                    const SizedBox(height: 12),
                    ServerItem(
                      key: const ValueKey('boosty_item'),
                      icon: CupertinoIcons.heart_fill,
                      actionIcon: SvgPicture.asset(
                        'assets/icons/boosty.svg',
                        width: 28,
                        height: 28,
                      ),
                      name: 'Поддержать Disalive на Boosty',
                      isActive: false,
                      isAction: true,
                      unreadCount: 0,
                      onTap: () => launchUrl(
                        Uri.parse('https://boosty.to/disalive'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ),
              if (state is ServersLoading || state is ServersInitial)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (state is ServersFailure)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () =>
                          context.read<ServersBloc>().add(const GetServers()),
                      child: const Icon(CupertinoIcons.refresh),
                    ),
                  ),
                )
              else if (state is ServersLoaded)
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  sliver: SliverList.builder(
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
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

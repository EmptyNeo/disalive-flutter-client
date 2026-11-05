import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/server_list_layout.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/repositories/server_list_repository.dart';
import 'package:disalive/presentation/features/chat/read_status_actions.dart';
import 'package:disalive/presentation/features/server/bloc/server_list_cubit.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/server/server_list_manage_screen.dart';
import 'package:disalive/presentation/features/server/widgets/server_item.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class ServersSidebar extends StatefulWidget {
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

  final int personalUnreadCount;
  final int? selectedServerId;
  final VoidCallback? onSelectDm;
  final ValueChanged<Server>? onSelectServer;
  final VoidCallback? onCreateServer;
  final VoidCallback? onDiscoverServers;
  final bool isDiscovering;

  @override
  State<ServersSidebar> createState() => _ServersSidebarState();
}

class _ServersSidebarState extends State<ServersSidebar> {
  ServerListCubit? _layoutCubit;
  List<int> _lastIds = const [];
  bool _syncedOnce = false;
  final Set<int> _expandedFolders = {};

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<ServerListRepository>() &&
        sl.isRegistered<ServerListCubit>()) {
      _layoutCubit = sl<ServerListCubit>();
    }
  }

  @override
  void dispose() {
    _layoutCubit?.close();
    super.dispose();
  }

  void _sync(List<Server> servers) {
    final ids = servers.map((server) => server.id).whereType<int>().toList();
    if (_syncedOnce &&
        _lastIds.length == ids.length &&
        List.generate(
          ids.length,
          (index) => _lastIds[index] == ids[index],
        ).every((same) => same)) {
      return;
    }
    _lastIds = ids;
    _syncedOnce = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _layoutCubit?.syncServers(ids);
      }
    });
  }

  void _manage(List<Server> servers) {
    final cubit = _layoutCubit;
    if (cubit != null) ServerListManageScreen.open(context, cubit, servers);
  }

  @override
  Widget build(BuildContext context) => Container(
    width: 72,
    color: AppColors.mainBackground,
    child: SafeArea(
      bottom: false,
      child: BlocBuilder<ServersBloc, ServersState>(
        builder: (context, state) {
          final servers = state is ServersLoaded
              ? state.servers
              : const <Server>[];
          if (state is ServersLoaded) _sync(servers);
          final hasUnread =
              widget.personalUnreadCount > 0 ||
              servers.any((server) => (server.newMessagesCount ?? 0) > 0);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    ServerItem(
                      key: const ValueKey('dm_server_item'),
                      icon: CupertinoIcons.chat_bubble_fill,
                      isActive:
                          widget.selectedServerId == null &&
                          !widget.isDiscovering,
                      isSpecial: true,
                      isAction: true,
                      unreadCount: widget.personalUnreadCount,
                      onTap: widget.onSelectDm,
                      onLongPress: hasUnread
                          ? () => ActionBottomSheet.show(
                              context,
                              actions: [
                                ActionItem(
                                  icon: CupertinoIcons.checkmark_circle,
                                  label: 'Пометить как прочитанное',
                                  onTap: () =>
                                      ReadStatusActions.markAllChatsAndServers(
                                        context,
                                      ),
                                ),
                              ],
                            )
                          : null,
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
                      onTap: widget.onCreateServer,
                    ),
                    const SizedBox(height: 12),
                    ServerItem(
                      key: const ValueKey('discover_servers_item'),
                      icon: CupertinoIcons.compass_fill,
                      isActive: widget.isDiscovering,
                      isAction: true,
                      unreadCount: 0,
                      onTap: widget.onDiscoverServers,
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
                    if (state is ServersLoaded && _layoutCubit != null) ...[
                      const SizedBox(height: 12),
                      ServerItem(
                        key: const ValueKey('manage_server_list'),
                        icon: CupertinoIcons.folder,
                        name: 'Управление списком серверов',
                        isActive: false,
                        isAction: true,
                        unreadCount: 0,
                        onTap: () => _manage(servers),
                      ),
                    ],
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
                _layoutCubit == null
                    ? _serverSliver(
                        servers
                            .where((s) => s.id != null)
                            .map((s) => ServerListItem.server(s.id!))
                            .toList(),
                        servers,
                      )
                    : BlocBuilder<ServerListCubit, ServerListState>(
                        bloc: _layoutCubit,
                        builder: (context, layoutState) => _serverSliver(
                          layoutState.loaded
                              ? layoutState.layout
                                    .reconcile(
                                      servers.map((s) => s.id).whereType<int>(),
                                    )
                                    .items
                              : servers
                                    .where((s) => s.id != null)
                                    .map((s) => ServerListItem.server(s.id!))
                                    .toList(),
                          servers,
                        ),
                      ),
            ],
          );
        },
      ),
    ),
  );

  Widget _serverSliver(List<ServerListItem> items, List<Server> servers) {
    final byId = {
      for (final server in servers)
        if (server.id != null) server.id!: server,
    };
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.isFolder) return _folderItem(item, byId, servers);
          final server = byId[item.serverId];
          return server == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey('server_${server.id}'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _serverItem(server, servers),
                );
        },
      ),
    );
  }

  Widget _serverItem(Server server, List<Server> servers) => ServerItem(
    icon: CupertinoIcons.group_solid,
    name: server.name,
    pathAvatar: server.pathAvatar,
    isActive: widget.selectedServerId == server.id,
    unreadCount: server.newMessagesCount ?? 0,
    onTap: () => widget.onSelectServer?.call(server),
    onLongPress: () => ActionBottomSheet.show(
      context,
      title: server.name,
      actions: [
        if ((server.newMessagesCount ?? 0) > 0)
          ActionItem(
            icon: CupertinoIcons.checkmark_circle,
            label: 'Пометить как прочитанное',
            onTap: () => ReadStatusActions.markServer(context, server),
          ),
        if (_layoutCubit != null)
          ActionItem(
            icon: CupertinoIcons.folder,
            label: 'Управление списком',
            onTap: () => _manage(servers),
          ),
      ],
    ),
  );

  Widget _folderItem(
    ServerListItem folder,
    Map<int, Server> byId,
    List<Server> servers,
  ) {
    final id = folder.folderId;
    final expanded = id != null && _expandedFolders.contains(id);
    final active = folder.servers.contains(widget.selectedServerId);
    final unread = folder.servers.fold<int>(
      0,
      (sum, serverId) => sum + (byId[serverId]?.newMessagesCount ?? 0),
    );
    return Padding(
      key: ValueKey('folder_$id'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Semantics(
            label: '${folder.name}, ${folder.servers.length} серверов',
            child: GestureDetector(
              onTap: () => setState(() {
                if (id != null && !_expandedFolders.add(id)) {
                  _expandedFolders.remove(id);
                }
              }),
              onLongPress: () => _manage(servers),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: expanded || active
                          ? AppColors.blurple
                          : AppColors.actionGrey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: expanded
                        ? const Icon(
                            CupertinoIcons.folder_fill,
                            color: CupertinoColors.white,
                          )
                        : _folderPreview(folder, byId),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              width: 72,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  for (final serverId in folder.servers)
                    if (byId[serverId] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _serverItem(byId[serverId]!, servers),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _folderPreview(ServerListItem folder, Map<int, Server> byId) {
    if (folder.servers.isEmpty) {
      return const Icon(CupertinoIcons.folder, color: CupertinoColors.white);
    }
    return Padding(
      padding: const EdgeInsets.all(7),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: [
          for (final id in folder.servers.take(4))
            ClipOval(
              child: Container(
                color: AppColors.mainBackground,
                child: byId[id]?.pathAvatar?.isNotEmpty == true
                    ? Image.network(
                        Domain.transformUrl(byId[id]!.pathAvatar),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _previewInitial(byId[id]),
                      )
                    : _previewInitial(byId[id]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _previewInitial(Server? server) => Center(
    child: Text(
      server?.name?.isNotEmpty == true
          ? server!.name!.substring(0, 1).toUpperCase()
          : '?',
      style: const TextStyle(color: CupertinoColors.white, fontSize: 10),
    ),
  );
}

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
import 'package:disalive/presentation/features/server/widgets/server_item.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/app_text_input_sheet.dart';
import 'package:disalive/presentation/widgets/modals/confirmation_modal.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
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
  final ScrollController _scrollController = ScrollController();
  List<int> _lastIds = const [];
  bool _syncedOnce = false;
  final Set<int> _expandedFolders = {};
  int? _draggingFolderId;
  final Map<String, GlobalKey> _dropKeys = {};
  String? _hoveredKey;
  int _hoverZone = 0;
  double _dragTravel = 0;

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
    _scrollController.dispose();
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

  Future<void> _folderActions(ServerListItem folder) async {
    if (folder.folderId == null || _layoutCubit?.state.saving == true) return;
    await ActionBottomSheet.show(
      context,
      title: folder.name,
      actions: [
        ActionItem(
          icon: CupertinoIcons.pencil,
          label: 'Переименовать папку',
          onTap: () async {
            final name = await AppTextInputSheet.show(
              context,
              title: 'Редактировать папку',
              initialValue: folder.name ?? '',
              actionLabel: 'Сохранить',
              maxLength: 50,
            );
            if (mounted && name != null) {
              await _layoutCubit?.renameFolder(folder.folderId!, name);
            }
          },
        ),
        ActionItem(
          icon: CupertinoIcons.delete,
          label: 'Удалить папку',
          isDestructive: true,
          onTap: () async {
            final confirmed = await showConfirmationDialog(
              context,
              title: 'Удалить папку?',
              description: 'Серверы останутся в общем списке.',
              confirmText: 'Удалить',
              isDestructive: true,
              icon: CupertinoIcons.folder_badge_minus,
            );
            if (confirmed == true && mounted) {
              await _layoutCubit?.deleteFolder(folder.folderId!);
              if (_layoutCubit?.state.layout.items.any(
                    (item) => item.folderId == folder.folderId,
                  ) ==
                  false) {
                _expandedFolders.remove(folder.folderId);
              }
            }
          },
        ),
      ],
    );
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
            controller: _scrollController,
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
                    : BlocConsumer<ServerListCubit, ServerListState>(
                        bloc: _layoutCubit,
                        listener: (context, layoutState) {
                          if (layoutState.error != null) {
                            CustomToast.open(
                              context: context,
                              message: layoutState.error!,
                            );
                          }
                        },
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
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == items.length) return _rootEndTarget();
          final item = items[index];
          if (item.isFolder) {
            return _rootDropTarget(item, _folderItem(item, byId));
          }
          final server = byId[item.serverId];
          return server == null
              ? const SizedBox.shrink()
              : _rootDropTarget(
                  item,
                  Padding(
                    key: ValueKey('server_${server.id}'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _draggableServer(server),
                  ),
                );
        },
      ),
    );
  }

  Widget _serverItem(Server server, {bool compact = false}) => ServerItem(
    icon: CupertinoIcons.group_solid,
    name: server.name,
    pathAvatar: server.pathAvatar,
    isActive: widget.selectedServerId == server.id,
    unreadCount: server.newMessagesCount ?? 0,
    compact: compact,
    onTap: () => widget.onSelectServer?.call(server),
  );

  Widget _folderItem(ServerListItem folder, Map<int, Server> byId) {
    final id = folder.folderId;
    final expanded = id != null && _expandedFolders.contains(id);
    final active = folder.servers.contains(widget.selectedServerId);
    final unread = folder.servers.fold<int>(
      0,
      (sum, serverId) => sum + (byId[serverId]?.newMessagesCount ?? 0),
    );
    return Padding(
      key: ValueKey('folder_$id'),
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: expanded ? AppColors.lightGrey : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Semantics(
              label: '${folder.name}, ${folder.servers.length} серверов',
              hint:
                  'Нажмите, чтобы раскрыть. Зажмите для действий или перетащите.',
              child: LongPressDraggable<ServerListItem>(
                data: folder,
                rootOverlay: true,
                maxSimultaneousDrags: _layoutCubit?.state.saving == true
                    ? 0
                    : 1,
                feedback: _dragFeedback(
                  expanded
                      ? const Icon(
                          CupertinoIcons.folder_fill,
                          color: CupertinoColors.white,
                        )
                      : _folderPreview(folder, byId),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.35,
                  child: _folderHeader(folder, byId, unread, active, expanded),
                ),
                onDragStarted: () => _dragTravel = 0,
                onDragUpdate: (details) {
                  _dragTravel += details.delta.distance;
                  if (_dragTravel > 8 && _draggingFolderId != id) {
                    setState(() => _draggingFolderId = id);
                  }
                },
                onDragEnd: (details) {
                  if (mounted && _draggingFolderId == id) {
                    setState(() => _draggingFolderId = null);
                  }
                  if (!details.wasAccepted && _dragTravel < 12) {
                    _folderActions(folder);
                  }
                },
                child: GestureDetector(
                  key: ValueKey('folder_header_$id'),
                  onTap: () => setState(() {
                    if (id != null && !_expandedFolders.add(id)) {
                      _expandedFolders.remove(id);
                    }
                  }),
                  child: _folderHeader(folder, byId, unread, active, expanded),
                ),
              ),
            ),
            Visibility(
              key: ValueKey('folder_contents_$id'),
              visible: _draggingFolderId != id,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 230),
                curve: Curves.easeOutCubic,
                child: expanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 6),
                        child: Column(
                          children: [
                            for (
                              var index = 0;
                              index < folder.servers.length;
                              index++
                            )
                              if (byId[folder.servers[index]] != null)
                                _folderChildTarget(
                                  folder,
                                  byId[folder.servers[index]]!,
                                  index,
                                ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _folderHeader(
    ServerListItem folder,
    Map<int, Server> byId,
    int unread,
    bool active,
    bool expanded,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active ? AppColors.blurple : AppColors.actionGrey,
            borderRadius: BorderRadius.circular(expanded ? 14 : 18),
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
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
  );

  Widget _folderChildTarget(ServerListItem folder, Server server, int index) {
    final key = 'child_${folder.folderId}_${server.id}';
    return DragTarget<ServerListItem>(
      onWillAcceptWithDetails: (details) =>
          _layoutCubit?.state.saving != true &&
          !details.data.isFolder &&
          details.data.serverId != server.id,
      key: _dropKey(key),
      onMove: (details) {
        _autoScroll(details.offset);
        _setHover(key, _zone(key, details.offset, allowCenter: false));
      },
      onLeave: (_) => _clearHover(key),
      onAcceptWithDetails: (details) {
        final after = _zone(key, details.offset, allowCenter: false) > 0;
        _clearHover(key);
        _layoutCubit?.placeServerInFolder(
          details.data.serverId!,
          folder.folderId!,
          index: index + (after ? 1 : 0),
        );
      },
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          border: Border(
            top: _hoveredKey == key && _hoverZone < 0
                ? BorderSide(color: AppColors.blurple, width: 3)
                : BorderSide.none,
            bottom: _hoveredKey == key && _hoverZone > 0
                ? BorderSide(color: AppColors.blurple, width: 3)
                : BorderSide.none,
          ),
        ),
        child: _draggableServer(server, compact: true),
      ),
    );
  }

  GlobalKey _dropKey(String value) =>
      _dropKeys.putIfAbsent(value, () => GlobalKey());

  int _zone(String key, Offset globalOffset, {bool allowCenter = true}) {
    final box = _dropKey(key).currentContext?.findRenderObject();
    if (box is! RenderBox) return 0;
    // DragTargetDetails.offset is the feedback's top-left, not the finger.
    final local = box.globalToLocal(globalOffset + const Offset(24, 24));
    final height = key.startsWith('root_folder_') ? 60.0 : box.size.height;
    if (!allowCenter) return local.dy < height / 2 ? -1 : 1;
    if (local.dy < 13) return -1;
    if (local.dy > height - 13) return 1;
    return 0;
  }

  void _setHover(String key, int zone) {
    if (_hoveredKey == key && _hoverZone == zone) return;
    setState(() {
      _hoveredKey = key;
      _hoverZone = zone;
    });
  }

  void _autoScroll(Offset globalOffset) {
    if (!_scrollController.hasClients) return;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final direction = globalOffset.dy < 96
        ? -1
        : globalOffset.dy > screenHeight - 96
        ? 1
        : 0;
    if (direction == 0) return;
    final position = _scrollController.position;
    final next = (_scrollController.offset + direction * 12).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (next != _scrollController.offset) _scrollController.jumpTo(next);
  }

  void _clearHover(String key) {
    if (_hoveredKey != key) return;
    setState(() {
      _hoveredKey = null;
      _hoverZone = 0;
    });
  }

  Widget _dragFeedback(Widget content) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.actionGrey,
      borderRadius: BorderRadius.circular(17),
      boxShadow: [
        BoxShadow(
          color: CupertinoColors.black.withValues(alpha: 0.4),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: SizedBox(width: 48, height: 48, child: content),
  );

  Widget _draggableServer(Server server, {bool compact = false}) {
    final item = ServerListItem.server(server.id!);
    return Semantics(
      hint: 'Зажмите и перетащите для изменения порядка или создания папки.',
      child: LongPressDraggable<ServerListItem>(
        data: item,
        rootOverlay: true,
        maxSimultaneousDrags: _layoutCubit?.state.saving == true ? 0 : 1,
        feedback: _dragFeedback(_serverItem(server, compact: true)),
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: _serverItem(server, compact: compact),
        ),
        onDragStarted: () => _dragTravel = 0,
        onDragUpdate: (details) => _dragTravel += details.delta.distance,
        onDragEnd: (details) {
          if (!details.wasAccepted &&
              _dragTravel < 12 &&
              (server.newMessagesCount ?? 0) > 0) {
            ActionBottomSheet.show(
              context,
              title: server.name,
              actions: [
                ActionItem(
                  icon: CupertinoIcons.checkmark_circle,
                  label: 'Пометить как прочитанное',
                  onTap: () => ReadStatusActions.markServer(context, server),
                ),
              ],
            );
          }
        },
        child: _serverItem(server, compact: compact),
      ),
    );
  }

  Widget _rootDropTarget(ServerListItem target, Widget child) {
    final key = target.isFolder
        ? 'root_folder_${target.folderId}'
        : 'root_server_${target.serverId}';
    final highlighted = _hoveredKey == key;
    return DragTarget<ServerListItem>(
      key: _dropKey(key),
      onWillAcceptWithDetails: (details) =>
          _layoutCubit?.state.loaded == true &&
          _layoutCubit?.state.saving != true &&
          details.data != target,
      onMove: (details) {
        _autoScroll(details.offset);
        _setHover(key, _zone(key, details.offset));
      },
      onLeave: (_) => _clearHover(key),
      onAcceptWithDetails: (details) {
        final zone = _zone(key, details.offset);
        _clearHover(key);
        final dragged = details.data;
        final cubit = _layoutCubit;
        if (cubit == null) return;
        if (zone == 0 && !dragged.isFolder && !target.isFolder) {
          cubit.groupServers(dragged.serverId!, target.serverId!);
        } else if (zone == 0 && !dragged.isFolder && target.isFolder) {
          cubit.placeServerInFolder(dragged.serverId!, target.folderId!);
          setState(() => _expandedFolders.add(target.folderId!));
        } else {
          cubit.placeAtRoot(dragged, target, after: zone >= 0);
        }
      },
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          border: Border(
            top: highlighted && _hoverZone < 0
                ? BorderSide(color: AppColors.blurple, width: 3)
                : BorderSide.none,
            bottom: highlighted && _hoverZone > 0
                ? BorderSide(color: AppColors.blurple, width: 3)
                : BorderSide.none,
          ),
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 170),
          scale: highlighted && _hoverZone == 0 ? 1.08 : 1,
          child: child,
        ),
      ),
    );
  }

  Widget _rootEndTarget() {
    const key = 'root_end';
    return DragTarget<ServerListItem>(
      key: _dropKey(key),
      onWillAcceptWithDetails: (_) =>
          _layoutCubit?.state.loaded == true &&
          _layoutCubit?.state.saving != true,
      onMove: (details) {
        _autoScroll(details.offset);
        _setHover(key, 0);
      },
      onLeave: (_) => _clearHover(key),
      onAcceptWithDetails: (details) {
        _clearHover(key);
        _layoutCubit?.appendAtRoot(details.data);
      },
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            top: _hoveredKey == key
                ? BorderSide(color: AppColors.blurple, width: 3)
                : BorderSide.none,
          ),
        ),
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
                        _serverAvatarUrl(byId[id]!.pathAvatar!),
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

  String _serverAvatarUrl(String path) {
    final transformed = Domain.transformUrl(path);
    final uri = Uri.tryParse(transformed);
    return uri?.hasScheme == true
        ? transformed
        : Uri.parse(Domain.imageDomain).resolve(transformed).toString();
  }
}

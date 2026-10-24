import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat/chat_screen.dart';
import 'package:disalive/presentation/features/dm_sidebar/dm_sidebar.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/server/server_content_sidebar.dart';
import 'package:disalive/presentation/features/server/server_form_screen.dart';
import 'package:disalive/presentation/features/server/server_discovery_sidebar.dart';
import 'package:disalive/presentation/features/server/servers_sidebar.dart';
import 'package:disalive/presentation/widgets/error_state_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatsView extends StatefulWidget {
  final bool isReconnect;
  final int personalUnreadCount;
  final ValueChanged<bool>? onDiscoveryChanged;
  final bool discoveryGridView;

  const ChatsView({
    super.key,
    required this.isReconnect,
    required this.personalUnreadCount,
    this.onDiscoveryChanged,
    this.discoveryGridView = false,
  });

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  bool _isDiscovering = false;

  void _setDiscovering(bool value) {
    if (_isDiscovering == value) return;
    setState(() => _isDiscovering = value);
    widget.onDiscoveryChanged?.call(value);
  }

  void _openDiscoveredServer(Server server, {bool refresh = false}) {
    final id = server.id;
    if (id == null) return;
    final repository = sl<ServerRepository>();
    final needsRefresh = repository.getByIdCached(id) == null;
    if (needsRefresh) {
      repository.updateCache([...repository.getCached(), server]);
    }
    _setDiscovering(false);
    final bloc = context.read<ServersBloc>();
    bloc.add(SelectServer(id));
    if (refresh || needsRefresh) bloc.add(const GetServers());
  }

  void _openChannel(ChannelServer channel) {
    ChatScreen.openServerChannel(context, channel, widget.isReconnect);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServersBloc, ServersState>(
      builder: (context, serversState) {
        Server? selectedServer;
        if (serversState is ServersLoaded) {
          for (final server in serversState.servers) {
            if (server.id == serversState.selectedServerId) {
              selectedServer = server;
              break;
            }
          }
        }
        final activeServerId = selectedServer?.id;

        return Stack(
          children: [
            Row(
              children: [
                const SizedBox(width: 72),
                Expanded(
                  child: Container(
                    color: AppColors.mainBackground,
                    child: _isDiscovering
                        ? ServerDiscoverySidebar(
                            gridView: widget.discoveryGridView,
                            onOpenServer: _openDiscoveredServer,
                            onJoinedServer: (server) =>
                                _openDiscoveredServer(server, refresh: true),
                          )
                        : selectedServer != null
                        ? ServerContentSidebar(
                            key: ValueKey(
                              'server_content_${selectedServer.id}',
                            ),
                            server: selectedServer,
                            onChannelTap: _openChannel,
                            onLeave: () => context.read<ServersBloc>().add(
                              const SelectServer(null),
                            ),
                          )
                        : _buildDirectMessages(context),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: ServersSidebar(
                personalUnreadCount: widget.personalUnreadCount,
                selectedServerId: activeServerId,
                isDiscovering: _isDiscovering,
                onSelectDm: () {
                  _setDiscovering(false);
                  context.read<ServersBloc>().add(const SelectServer(null));
                },
                onSelectServer: (server) {
                  _setDiscovering(false);
                  context.read<ServersBloc>().add(SelectServer(server.id));
                },
                onDiscoverServers: () {
                  _setDiscovering(true);
                  context.read<ServersBloc>().add(const SelectServer(null));
                },
                onCreateServer: () async {
                  final serversBloc = context.read<ServersBloc>();
                  final server = await ServerFormScreen.open(context);
                  if (mounted && server?.id != null) {
                    _setDiscovering(false);
                    serversBloc.add(SelectServer(server!.id));
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDirectMessages(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatLoading || state is ChatInitial) {
          return DirectMessagesSidebar(
            chats: const [],
            isLoading: true,
            isReconnect: widget.isReconnect,
          );
        }
        if (state is ChatLoaded) {
          return DirectMessagesSidebar(
            chats: state.chats,
            isReconnect: widget.isReconnect,
          );
        }
        if (state is ChatFailure) {
          return ErrorStateView(
            failure: state.error,
            onRetry: () => context.read<ChatBloc>().add(GetChats()),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

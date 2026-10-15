import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/chat/chat_screen.dart';
import 'package:disalive/presentation/features/dm_sidebar/dm_sidebar.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/server/server_content_sidebar.dart';
import 'package:disalive/presentation/features/server/server_form_screen.dart';
import 'package:disalive/presentation/features/server/servers_sidebar.dart';
import 'package:disalive/presentation/widgets/error_state_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatsView extends StatefulWidget {
  final bool isReconnect;
  final int personalUnreadCount;

  const ChatsView({
    super.key,
    required this.isReconnect,
    required this.personalUnreadCount,
  });

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  void _openChannel(ChannelServer channel) {
    final chatId = channel.chatId;
    if (chatId == null) return;
    final cached = sl<ChatRepository>().getCached();
    final cachedChat = cached.where((item) => item.id == chatId).firstOrNull;
    final chat =
        cachedChat?.copyWith(
          type: ChatType.channel,
          name: channel.chatName ?? cachedChat.name,
        ) ??
        Chat(
          id: chatId,
          name: channel.chatName ?? 'Канал',
          type: ChatType.channel,
          newMessagesCount: channel.newMessagesCount,
        );
    ChatScreen.open(context, chat, widget.isReconnect);
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

        return Row(
          children: [
            ServersSidebar(
              personalUnreadCount: widget.personalUnreadCount,
              selectedServerId: activeServerId,
              onSelectDm: () =>
                  context.read<ServersBloc>().add(const SelectServer(null)),
              onSelectServer: (server) =>
                  context.read<ServersBloc>().add(SelectServer(server.id)),
              onCreateServer: () async {
                final serversBloc = context.read<ServersBloc>();
                final server = await ServerFormScreen.open(context);
                if (mounted && server?.id != null) {
                  serversBloc.add(SelectServer(server!.id));
                }
              },
            ),
            Expanded(
              child: Container(
                color: AppColors.mainBackground,
                child: selectedServer != null
                    ? ServerContentSidebar(
                        key: ValueKey('server_content_${selectedServer.id}'),
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

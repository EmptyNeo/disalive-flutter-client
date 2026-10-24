import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/channel_server.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/member.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/domain/services/read_status_service.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReadStatusActions {
  static Future<void> markAllChatsAndServers(BuildContext context) async {
    await markAllChats(context);
    if (context.mounted) await markAllServers(context);
  }

  static Future<void> markChat(BuildContext context, Chat chat) async {
    final bloc = context.read<ChatBloc>();
    final result = await sl<ReadStatusService>().markChat(chat);
    if (!context.mounted) return;
    result.fold((failure) => _showError(context, failure), (readId) {
      if (readId != null) _updateChatLocally(bloc, chat, readId);
    });
  }

  static Future<void> markAllChats(BuildContext context) async {
    final bloc = context.read<ChatBloc>();
    final chats = sl<ChatRepository>()
        .getCached()
        .where((chat) => chat.unreadCount > 0)
        .toList();
    Failure? firstFailure;
    for (final chat in chats) {
      final result = await sl<ReadStatusService>().markChat(chat);
      result.fold((failure) => firstFailure ??= failure, (readId) {
        if (readId != null && !bloc.isClosed) {
          _updateChatLocally(bloc, chat, readId);
        }
      });
    }
    if (!context.mounted) return;
    if (firstFailure != null) _showError(context, firstFailure!);
  }

  static Future<void> markChannel(
    BuildContext context,
    int serverId,
    ChannelServer channel, {
    VoidCallback? refreshChannels,
  }) async {
    final serversBloc = context.read<ServersBloc>();
    final result = await sl<ReadStatusService>().markChannel(serverId, channel);
    if (!context.mounted) return;
    result.fold((failure) => _showError(context, failure), (_) {
      serversBloc.add(const GetServers());
      refreshChannels?.call();
    });
  }

  static Future<void> markServer(
    BuildContext context,
    Server server, {
    VoidCallback? refreshChannels,
  }) async {
    final bloc = context.read<ServersBloc>();
    final result = await sl<ReadStatusService>().markServer(server);
    if (!context.mounted) return;
    result.fold((failure) => _showError(context, failure), (_) {});
    // Other channels may have succeeded before one request failed.
    bloc.add(const GetServers());
    refreshChannels?.call();
  }

  static Future<void> markAllServers(
    BuildContext context, {
    VoidCallback? refreshChannels,
  }) async {
    final bloc = context.read<ServersBloc>();
    final servers = sl<ServerRepository>()
        .getCached()
        .where((server) => (server.newMessagesCount ?? 0) > 0)
        .toList();
    Failure? firstFailure;
    for (final server in servers) {
      final result = await sl<ReadStatusService>().markServer(server);
      result.fold((failure) => firstFailure ??= failure, (_) {});
    }
    if (!context.mounted) return;
    if (servers.isNotEmpty) {
      bloc.add(const GetServers());
      refreshChannels?.call();
    }
    if (firstFailure != null) _showError(context, firstFailure!);
  }

  static void _showError(BuildContext context, Failure failure) {
    CustomToast.open(context: context, message: failure.message);
  }

  static void _updateChatLocally(ChatBloc bloc, Chat chat, int readId) {
    bloc.add(
      UpdateMemberInChat(
        chatId: chat.id,
        userId: sl<UserRepository>().getCurrentUser()?.id ?? 0,
        member: Member(lastIdReadMessage: readId),
        isSelf: true,
      ),
    );
  }
}

// presentation/features/profile/determinant_profile_screen.dart
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/media_filter_item.dart';
import 'package:disalive/domain/repositories/chat_repository.dart';
import 'package:disalive/presentation/features/chat/chat_screen.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/media_stats/bloc/media_stats_bloc.dart';
import 'package:disalive/presentation/features/server/bloc/servers_bloc.dart';
import 'package:disalive/presentation/features/profile/direct_profile_screen.dart';
import 'package:disalive/presentation/features/profile/channel_profile_screen.dart';
import 'package:disalive/presentation/features/profile/group_profile_screen.dart';
import 'package:disalive/presentation/features/profile/solo_chat_profile_screen.dart';
import 'package:disalive/presentation/features/profile/widgets/media_stats_section.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeterminantProfileScreen {
  static Future<void> open(
    BuildContext context, {
    required Chat chat,
    ValueChanged<MediaStatsCategory>? onMediaCategoryTap,
    ValueChanged<int>? onMessageTap,
  }) {
    if (chat.type == ChatType.channel) {
      final membersBloc = context.read<MembersBloc>();
      final server = sl.isRegistered<ServerRepository>()
          ? sl<ServerRepository>().selectedServer
          : null;
      return SwipeToDismissRoute.push(
        context,
        (_) => BlocProvider.value(
          value: membersBloc,
          child: ChannelProfileScreen(chat: chat, server: server),
        ),
      );
    }
    final mediaStatsBloc = context.read<MediaStatsBloc>()
      ..add(const LoadMediaStats(force: true));
    void openGroup(MediaFilterMutualGroup group) {
      if (!context.mounted) return;
      final cached = sl<ChatRepository>().getCached();
      final chat =
          cached.where((item) => item.id == group.idChat).firstOrNull ??
          Chat(
            id: group.idChat,
            name: group.name,
            pathImage: group.pathImage,
            memberCount: group.memberCount,
            type: ChatType.group,
          );
      ChatScreen.open(context, chat, false);
    }

    void openServer(MediaFilterMutualServer server) {
      if (!context.mounted) return;
      context.read<ServersBloc>().add(SelectServer(server.idServer));
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    if (chat.isSoloChat ?? false) {
      return SwipeToDismissRoute.push(
        context,
        (_) => BlocProvider.value(
          value: mediaStatsBloc,
          child: SoloChatProfileScreen(
            chat: chat,
            onMediaCategoryTap: onMediaCategoryTap,
            onMessageTap: onMessageTap,
          ),
        ),
      );
    }
    ChatBloc chatBloc = context.read<ChatBloc>();
    if (chat.isPersonalChat) {
      return SwipeToDismissRoute.push(
        context,
        (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: chatBloc),
            BlocProvider.value(value: mediaStatsBloc),
          ],
          child: DirectProfileScreen(
            chat: chat,
            onMediaCategoryTap: onMediaCategoryTap,
            onGroupTap: openGroup,
            onServerTap: openServer,
            onMessageTap: onMessageTap,
          ),
        ),
      );
    } else {
      MembersBloc membersBloc = context.read<MembersBloc>();
      return SwipeToDismissRoute.push(
        context,
        (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: chatBloc),
            BlocProvider.value(value: membersBloc),
            BlocProvider.value(value: mediaStatsBloc),
          ],
          child: GroupProfileScreen(
            chat: chat,
            onMediaCategoryTap: onMediaCategoryTap,
            onGroupTap: openGroup,
            onMessageTap: onMessageTap,
          ),
        ),
      );
    }
  }
}

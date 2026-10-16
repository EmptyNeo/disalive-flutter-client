// presentation/features/profile/determinant_profile_screen.dart
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/chat_type.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/repositories/server_repository.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/media_stats/bloc/media_stats_bloc.dart';
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
    if (chat.isSoloChat ?? false) {
      return SwipeToDismissRoute.push(
        context,
        (_) => BlocProvider.value(
          value: mediaStatsBloc,
          child: SoloChatProfileScreen(
            chat: chat,
            onMediaCategoryTap: onMediaCategoryTap,
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
          ),
        ),
      );
    }
  }
}

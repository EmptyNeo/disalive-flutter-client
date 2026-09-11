// presentation/features/profile/determinant_profile_screen.dart
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/members/bloc/members_bloc.dart';
import 'package:disalive/presentation/features/profile/direct_profile_screen.dart';
import 'package:disalive/presentation/features/profile/group_profile_screen.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeterminantProfileScreen {
  static Future<void> open(BuildContext context, {required Chat chat}) {
    ChatBloc chatBloc = context.read<ChatBloc>();
    MembersBloc membersBloc = context.read<MembersBloc>();
    if (chat.isSoloChat ?? false) {
      return Future.value();
    }
    if (chat.isPersonalChat) {
      return SwipeToDismissRoute.push(
        context,
        (context) => BlocProvider.value(
          value: chatBloc,
          child: DirectProfileScreen(chat: chat),
        ),
      );
    } else {
      return SwipeToDismissRoute.push(
        context,
        (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: chatBloc),
            BlocProvider.value(value: membersBloc),
          ],
          child: GroupProfileScreen(chat: chat),
        ),
      );
    }
  }
}

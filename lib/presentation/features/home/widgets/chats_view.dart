import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/dm_sidebar/dm_sidebar.dart';
import 'package:disalive/presentation/features/server/servers_sidebar.dart';
import 'package:disalive/presentation/widgets/error_state_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:disalive/app/theme/app_theme.dart';

class ChatsView extends StatelessWidget {
  final bool isReconnect;
  final int personalUnreadCount;

  const ChatsView({
    super.key,
    required this.isReconnect,
    required this.personalUnreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Левый сайдбар (Сервера)
        ServersSidebar(personalUnreadCount: personalUnreadCount),

        // Правая часть (Личные сообщения / Чаты)
        Expanded(
          child: Container(
            color: AppColors.mainBackground,
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                // Loading/Initial больше не подменяют весь сайдбар спиннером
                // по центру экрана — шапка (заголовок, поиск, «Добавить в
                // друзей») остаётся на месте, крутится только область
                // списка внутри DirectMessagesSidebar.
                if (state is ChatLoading || state is ChatInitial) {
                  return DirectMessagesSidebar(
                    chats: [],
                    isLoading: true,
                    isReconnect: isReconnect,
                  );
                }

                if (state is ChatLoaded) {
                  return DirectMessagesSidebar(
                    chats: state.chats,
                    isReconnect: isReconnect,
                  );
                }

                if (state is ChatFailure) {
                  return ErrorStateView(
                    failure: state.error,
                    onRetry: () => {context.read<ChatBloc>().add(GetChats())},
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ],
    );
  }
}

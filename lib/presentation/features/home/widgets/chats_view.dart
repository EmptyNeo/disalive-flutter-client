import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/home/widgets/dm_sidebar.dart';
import 'package:disalive/presentation/features/server/servers_sidebar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:disalive/app/theme/app_theme.dart';

class ChatsView extends StatelessWidget {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Левый сайдбар (Сервера)
        const ServersSidebar(),

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
                  return const DirectMessagesSidebar(
                    chats: [],
                    isLoading: true,
                  );
                }

                if (state is ChatLoaded) {
                  return DirectMessagesSidebar(chats: state.chats);
                }

                if (state is ChatFailure) {
                  return Center(
                    child: Text(
                      'Ошибка загрузки: ${state.error}',
                      style: const TextStyle(color: CupertinoColors.white),
                    ),
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
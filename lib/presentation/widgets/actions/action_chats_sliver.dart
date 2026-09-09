import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/widgets/select_chat_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActionChatsSliver extends StatelessWidget {
  final Function(Chat) _onTap;
  final List<Chat> Function(ChatState) _filter;
  final Map<int, Chat> _selected;

  const ActionChatsSliver({
    super.key,
    required Function(Chat) onTap,
    required List<Chat> Function(ChatState) filter,
    required Map<int, Chat> selected,
  }) : _onTap = onTap,
       _filter = filter,
       _selected = selected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      bloc: context.read<ChatBloc>(),
      builder: (context, state) {
        if (state is ChatLoading) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        if (state is ChatFailure) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                state.error,
                style: TextStyle(color: AppColors.greyple, fontSize: 14),
              ),
            ),
          );
        }

        final chats = _filter(state);

        if (chats.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'Друзья не найдены',
                style: TextStyle(color: AppColors.greyple, fontSize: 14),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final chat = chats[index];
              final id = chat.id;
              return SelectChatItem(
                key: ValueKey(id),
                chat: chat,
                isSelected: _selected.containsKey(id),
                onTap: () => _onTap(chat),
              );
            }, childCount: chats.length),
          ),
        );
      },
    );
  }
}

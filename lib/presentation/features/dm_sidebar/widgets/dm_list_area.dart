import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/presentation/features/chat/widgets/chat_item.dart';
import 'package:flutter/cupertino.dart';

class DmListArea extends StatelessWidget {
  final List<Chat> chats;
  final bool isLoading;
  final bool isSearchActive;

  const DmListArea({
    super.key,
    required this.chats,
    this.isLoading = false,
    this.isSearchActive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (chats.isEmpty) {
      return Center(
        child: Text(
          isSearchActive ? 'Ничего не найдено' : 'У вас пока нет чатов',
          style: TextStyle(color: AppColors.white.withOpacity(0.3)),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(
        bottom: 100, // Отступ под нижнее меню
      ),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        return ChatItem(chat: chats[index]);
      },
    );
  }
}
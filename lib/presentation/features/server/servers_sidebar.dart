import 'package:disalive/presentation/features/server/widgets/server_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:disalive/app/theme/app_theme.dart';

class ServersSidebar extends StatelessWidget {
  final int personalUnreadCount;

  const ServersSidebar({super.key, required this.personalUnreadCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      // Чуть более темный фон для сайдбара серверов, как в Discord
      color: AppColors.mainBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Кнопка Личных сообщений (активна по умолчанию)
            ServerItem(
              icon: CupertinoIcons.chat_bubble_fill,
              isActive: true,
              isSpecial: true,
              unreadCount: personalUnreadCount,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 2,
                color: CupertinoColors.white.withOpacity(0.1),
              ),
            ),

            // Кнопка добавления сервера
            ServerItem(
              icon: CupertinoIcons.add,
              isActive: false,
              isAction: true,
              unreadCount: 0,
            ),

            // Здесь будет ListView с остальными серверами
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                // Отступ под нижнее меню
                itemCount: 3,
                // Заглушка
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ServerItem(
                      icon: CupertinoIcons.group_solid,
                      isActive: false,
                      unreadCount: 0,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

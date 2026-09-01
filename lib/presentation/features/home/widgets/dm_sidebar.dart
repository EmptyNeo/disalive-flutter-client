import 'dart:ui';

import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/presentation/features/chat/widgets/chat_item.dart';
import 'package:disalive/presentation/widgets/buttons/glass_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:disalive/app/theme/app_theme.dart';

class DirectMessagesSidebar extends StatelessWidget {
  final List<Chat> chats;

  // Раньше на время загрузки весь DirectMessagesSidebar подменялся на
  // спиннер снаружи (в ChatsView) — шапка с поиском/«Добавить в друзей»
  // моргала при каждом рефреше. Теперь шапка и граница всегда на месте, а
  // isLoading решает, что показать только в области списка.
  final bool isLoading;

  const DirectMessagesSidebar({
    super.key,
    required this.chats,
    this.isLoading = false,
  });

  static const double _panelRadius = 28;
  static const double _buttonRadius = 32;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_panelRadius),
          ),
          border: Border.all(
            color: AppColors.white.withOpacity(0.10),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_panelRadius),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.lightGrey.withOpacity(0.72),
                    AppColors.lightGrey.withOpacity(0.55),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 16, 14),
                    child: Text(
                      'Личные сообщения',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),

                  // Панель поиска и добавления в друзья
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        GlassButton(
                          borderRadius: _buttonRadius,
                          padding: const EdgeInsets.all(11),
                          child: Icon(
                            CupertinoIcons.search,
                            color: AppColors.white.withOpacity(0.75),
                            size: 18,
                          ),
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: GlassButton(
                            borderRadius: _buttonRadius,
                            padding: const EdgeInsets.symmetric(
                              vertical: 11,
                              horizontal: 14,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Icon(
                                  CupertinoIcons.person_add_solid,
                                  color: AppColors.white.withOpacity(0.75),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Добавить в друзей',
                                    style: TextStyle(
                                      color: AppColors.white.withOpacity(0.85),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    height: 1,
                    color: AppColors.white.withOpacity(0.10),
                  ),

                  Expanded(child: _buildListArea()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListArea() {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (chats.isEmpty) {
      return Center(
        child: Text(
          'У вас пока нет чатов',
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

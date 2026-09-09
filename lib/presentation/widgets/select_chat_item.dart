import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/check_circle.dart';
import 'package:flutter/cupertino.dart';

/// Строка выбора чата: аватар + имя + опциональная метка
/// "закреплён" + чекбокс справа. Тап по всей строке (а не только по
/// чекбоксу) переключает выбор — сделан отдельным виджетом намеренно,
/// чтобы годился для любого списка "выбрать людей" (создание группы,
/// добавление участников и т.п.), а не только для конкретного экрана.
class SelectChatItem extends StatelessWidget {
  final Chat chat;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectChatItem({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            BuildAvatar(
              url: chat.urlAvatar,
              isBookmark: chat.isSoloChat ?? false,
              isGroup: chat.isGroup,
              wh: 32,
              size: 22,
              status: chat.isPersonalChat ? chat.user?.status : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      chat.name,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (chat.member!.isFixed) ...[
                    const SizedBox(width: 6),
                    Icon(
                      CupertinoIcons.pin_fill,
                      color: AppColors.iconGrey,
                      size: 13,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            CheckCircle(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

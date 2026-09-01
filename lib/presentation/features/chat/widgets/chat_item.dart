import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/presentation/features/chat/chat_screen.dart';
import 'package:disalive/presentation/utils/util_date.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:flutter/cupertino.dart';

class ChatItem extends StatefulWidget {
  final Chat chat;

  const ChatItem({super.key, required this.chat});

  @override
  State<ChatItem> createState() => _ChatItemState();
}

class _ChatItemState extends State<ChatItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final bool isPinned = chat.member?.isFixed ?? false;
    final bool isMuted = chat.member?.isMuted ?? false;
    final int unreadCount = chat.newMessagesCount ?? 0;
    final bool hasUnread = chat.hasUnreadMessages;
    final String? time = UtilDate.formatChatTime(chat.lastMessageTime);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ChatScreen.open(context, chat),
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _pressed
              ? AppColors.white.withOpacity(0.06)
              : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BuildAvatar(
              url: chat.urlAvatar,
              isBookmark: chat.isSoloChat ?? false,
              wh: 32,
              size: 22,
              status: chat.isPersonalChat ? chat.user?.status : null,
              statusBackgroundColor: _pressed
                  ? AppColors
                        .glassPanelTop // При нажатии
                  : AppColors.lightGrey, // Обычное состояние
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Верхняя строка: имя слева (гибкое), время справа
                  // (фиксированное, короткое — больше не съедает всё место).
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isMuted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.speaker_slash_fill,
                          color: AppColors.iconGrey,
                          size: 13,
                        ),
                      ],
                      if (time != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          time,
                          style: TextStyle(
                            color: hasUnread
                                ? AppColors.blurple
                                : AppColors.iconGrey,
                            fontSize: 12,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Нижняя строка: подпись (кол-во участников) слева, пин и
                  // бейдж непрочитанных справа.
                  Row(
                    children: [
                      Expanded(
                        child: (chat.isGroupChat && chat.memberCount != null)
                            ? Text(
                                '${chat.memberCount} участников',
                                style: TextStyle(
                                  color: AppColors.greyple,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : const SizedBox(height: 0),
                      ),
                      if (isPinned) ...[
                        Icon(
                          CupertinoIcons.pin_fill,
                          color: AppColors.iconGrey,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (hasUnread)
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            // Если чат в муте, бейдж серый, иначе акцентный
                            color: isMuted
                                ? AppColors.mainGrey
                                : AppColors.blurple,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

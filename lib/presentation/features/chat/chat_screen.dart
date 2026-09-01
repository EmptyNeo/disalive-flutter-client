import 'dart:ui';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  static Future<void> open(BuildContext context, Chat chat) {
    return SwipeToDismissRoute.push(
      context,
      (context) => ChatScreen(chat: chat),
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController _textController;
  final ValueNotifier<bool> _hasText = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (_hasText.value != hasText) {
      _hasText.value = hasText;
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _hasText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      color: AppColors.mainBackground.withValues(alpha: 0.55),
                      child: Column(
                        children: [
                          _buildHeader(context),
                          Container(
                            height: 1,
                            color: AppColors.divider.withValues(alpha: 0.3),
                          ),
                          const Expanded(child: SizedBox.expand()),
                          _buildInputArea(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Row(
        children: [
          GlassIconButton(
            icon: CupertinoIcons.back,
            onTap: () => Navigator.of(context).pop(),
            size: 32,
          ),
          const SizedBox(width: 12),
          BuildAvatar(
            url: widget.chat.urlAvatar,
            wh: 26,
            size: 20,
            status: widget.chat.user?.status,
            statusSize: 6,
            statusBackgroundColor: AppColors.lightGrey,
            isBookmark: widget.chat.isSoloChat ?? false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.chat.name,
                  style: AppText.mediumTextStyle.copyWith(
                    color: AppColors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (widget.chat.isSoloChat == false) ...[
            GlassIconButton(
              icon: CupertinoIcons.phone_fill,
              onTap: () {
                // TODO: Инициализация LiveKit для аудио/видео звонков
              },
              size: 32,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GlassIconButton(
            icon: CupertinoIcons.add,
            onTap: () {
              // TODO: Логика прикрепления медиа
            },
            size: 36,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.actionGrey.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.08),
                ),
              ),
              child: CupertinoTextField(
                controller: _textController,
                minLines: 1,
                maxLines: 3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                placeholder: 'Сообщение...',
                placeholderStyle: AppText.mediumTextStyle.copyWith(
                  color: AppColors.greyple,
                ),
                style: AppText.mediumTextStyle.copyWith(color: AppColors.white),
                decoration: null, // Убираем стандартную обводку
              ),
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<bool>(
            valueListenable: _hasText,
            builder: (context, hasText, _) {
              return GlassIconButton(
                icon: hasText
                    ? CupertinoIcons.arrow_up
                    : CupertinoIcons.mic_solid,
                filled: hasText,
                onTap: () {
                  if (hasText) {
                    // TODO: Логика отправки текста
                    _textController.clear();
                  } else {
                    // TODO: Логика записи голосового сообщения
                  }
                },
                size: 36,
              );
            },
          ),
        ],
      ),
    );
  }
}

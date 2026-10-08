import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/gif_type_search.dart';
import 'package:disalive/domain/models/emojis/emoji_definition.dart';
import 'package:disalive/domain/models/gif.dart';
import 'package:disalive/domain/models/preferred_reaction.dart';
import 'package:disalive/domain/models/sticker_content.dart';
import 'package:disalive/domain/models/sticker_pack.dart';
import 'package:disalive/presentation/features/chat/widgets/symbols/tabs/emojis_tab.dart';
import 'package:disalive/presentation/features/chat/widgets/symbols/tabs/gifs_tab.dart';
import 'package:disalive/presentation/features/chat/widgets/symbols/tabs/stickers_tab.dart';
import 'package:disalive/presentation/features/gifs/bloc/gif_bloc.dart';
import 'package:disalive/presentation/features/stickers/bloc/stickers_pack_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatExtraPanel extends StatefulWidget {
  final double height;
  final VoidCallback onClose;
  final Function(EmojiDefinition emoji) onTapEmoji;
  final Function(StickerContent sticker) onTapSticker;
  final Function(Gif gif) onTapGif;
  final VoidCallback onBackspace;

  const ChatExtraPanel({
    super.key,
    required this.height,
    required this.onClose,
    required this.onTapEmoji,
    required this.onTapSticker,
    required this.onTapGif,
    required this.onBackspace,
  });

  @override
  State<ChatExtraPanel> createState() => _ChatExtraPanelState();
}

class _ChatExtraPanelState extends State<ChatExtraPanel>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    // Инициализация BLoC при открытии
    context.read<StickersPackBloc>().add(const LoadStickerPacks(skip: 0, take: 10));
    context.read<GifBloc>().add(
      const LoadGifs(type: GifTypeSearch.popular, tags: '', skip: 0, take: 20),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 ОПТИМИЗИРОВАННОЕ СТЕКЛО (Glassmorphism)
    // sigma: 8 - безопасно для GPU, alpha: 0.85 дает плотность, border дает эффект кромки
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_animation),
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          height: widget.height,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            border: Border.all(color: AppColors.divider, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            child: Column(
              children: [
                // Индикатор для свайпа вниз
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyple.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Табы
                Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: _buildTabBar(),
                ),
                const Divider(height: 1, color: Colors.white10),
                // Контент
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      EmojisTab(
                        onTap: widget.onTapEmoji,
                        onBackspace: widget.onBackspace,
                      ),
                      StickersTab(
                        onTap: widget.onTapSticker,
                      ),
                      GifsTab(onTap: widget.onTapGif),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Эмодзи', 'Стикеры', 'GIF'];
    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = _currentIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _currentIndex = index),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? AppColors.blurple.withValues(alpha: 0.2)
                        : Colors.transparent,
                  ),
                  child: Text(
                    tabs[index],
                    style: AppText.mediumTextStyle.copyWith(
                      color: isSelected ? AppColors.blurple : AppColors.greyple,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/emojis/emoji_definition.dart';
import 'package:disalive/domain/models/preferred_reaction.dart';
import 'package:disalive/domain/services/emojis_handler.dart';
import 'package:disalive/presentation/widgets/custom_divider.dart';
import 'package:disalive/presentation/widgets/emoji_widget.dart';
import 'package:flutter/cupertino.dart';

class EmojisTab extends StatefulWidget {
  final Function(EmojiDefinition emoji) onTap;
  final VoidCallback? onBackspace;
  final List<PreferredReaction>? preferredReactions;

  const EmojisTab({
    super.key,
    required this.onTap,
    this.onBackspace,
    this.preferredReactions,
  });

  @override
  State<EmojisTab> createState() => _EmojisTabState();
}

class _EmojisTabState extends State<EmojisTab> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  List<String> _categories = [];
  final frequentKey = 'frequent';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    _categories = EmojisHandler.instance.categoryNames;

    if (widget.preferredReactions != null &&
        widget.preferredReactions!.isNotEmpty) {
      _categories.insert(0, frequentKey);
    }

    for (var name in _categories) {
      _categoryKeys[name] = GlobalKey();
    }
  }

  void _scrollToCategory(String categoryName) {
    final key = _categoryKeys[categoryName];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final categoryName = _categories[index];

                  if (categoryName == frequentKey) {
                    return _buildFrequentCategory(context);
                  }

                  final sheetData = EmojisHandler.instance.getSheetDataByName(
                    categoryName,
                  );
                  if (sheetData == null) return const SizedBox.shrink();

                  return Container(
                    key: _categoryKeys[categoryName],
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            categoryName,
                            style: AppText.lowTextStyle.copyWith(
                              color: AppColors.greyple,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 8,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                              ),
                          itemCount: sheetData.emojis.length,
                          itemBuilder: (context, i) {
                            final emoji = sheetData.emojis.values.elementAt(i);
                            return EmojiWidget(
                              emoji: emoji,
                              sheetData: sheetData,
                              size: 30,
                              onTap: widget.onTap,
                              animate: false,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const CustomDivider(),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final categoryName = _categories[index];

                  // 🎯 СПЕЦИАЛЬНАЯ ОБРАБОТКА ДЛЯ КАТЕГОРИИ "ЧАСТЫЕ"
                  if (categoryName == frequentKey) {
                    return GestureDetector(
                      onTap: () => _scrollToCategory(frequentKey),
                      child: Container(
                        width: 36,
                        margin: EdgeInsets.only(
                          left: index == 0 ? 0 : 2,
                          right: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.white.withValues(alpha: 0.05),
                        ),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.clock,
                            color: AppColors.greyple,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }

                  final sheetData = EmojisHandler.instance.getSheetDataByName(
                    categoryName,
                  );

                  if (sheetData == null) return const SizedBox.shrink();

                  final firstEmoji = sheetData.emojis.values.firstOrNull;

                  return GestureDetector(
                    onTap: () => _scrollToCategory(categoryName),
                    child: Container(
                      width: 36,
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 2,
                        right: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.white.withValues(alpha: 0.05),
                      ),
                      child: Center(
                        child: firstEmoji != null
                            ? EmojiWidget(
                                emoji: firstEmoji,
                                sheetData: sheetData,
                                size: 24,
                                animate: false,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (widget.onBackspace != null) ...[
          Positioned(
            bottom: 46,
            right: 4,
            child: GestureDetector(
              onTap: widget.onBackspace,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.lightGrey,
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: Icon(
                  CupertinoIcons.delete_left,
                  color: AppColors.greyple,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFrequentCategory(BuildContext context) {
    if (widget.preferredReactions == null ||
        widget.preferredReactions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      key: _categoryKeys[frequentKey],
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              'Частые реакции',
              style: AppText.lowTextStyle.copyWith(
                color: AppColors.greyple,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: widget.preferredReactions!.length,
            itemBuilder: (context, i) {
              final prefReaction = widget.preferredReactions![i];
              final emoji = EmojisHandler.instance.getEmojiByName(
                prefReaction.nameReaction ?? '',
              );

              if (emoji == null) return const SizedBox.shrink();

              final sheetData = EmojisHandler.instance.getSheetDataByCategory(
                emoji.categoryName ?? '',
              );

              if (sheetData == null) return const SizedBox.shrink();

              return EmojiWidget(
                emoji: emoji,
                sheetData: sheetData,
                size: 30,
                onTap: (e) => widget.onTap(e),
                animate: false,
              );
            },
          ),
        ],
      ),
    );
  }
}

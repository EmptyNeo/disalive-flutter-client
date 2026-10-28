import 'dart:math' as math;

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
  List<String> _categories = [];
  final frequentKey = 'frequent';
  double _contentWidth = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadCategories() {
    _categories = EmojisHandler.instance.categoryNames;

    if (widget.preferredReactions != null &&
        widget.preferredReactions!.isNotEmpty) {
      _categories.insert(0, frequentKey);
    }
  }

  double _categoryExtent(String name, double width) {
    final isFrequent = name == frequentKey;
    final count = isFrequent
        ? widget.preferredReactions?.length ?? 0
        : EmojisHandler.instance.getSheetDataByName(name)?.emojis.length ?? 0;
    final style = AppText.lowTextStyle.copyWith(
      color: AppColors.greyple,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
    );
    final painter = TextPainter(
      text: TextSpan(text: isFrequent ? 'Частые реакции' : name, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width - 4);
    final headerHeight = painter.height + (isFrequent ? 4 : 8);
    painter.dispose();

    final rows = (count + 7) ~/ 8;
    final cellSize = (width - 7 * 4) / 8;
    final gridHeight = rows == 0 ? 0.0 : rows * cellSize + (rows - 1) * 4;
    return headerHeight + gridHeight + (isFrequent ? 8 : 16);
  }

  void _scrollToCategory(String categoryName) {
    final index = _categories.indexOf(categoryName);
    if (index < 0 || !_scrollController.hasClients) return;

    // The list has exact extents, so even sections outside the viewport have
    // a stable offset and do not need a mounted BuildContext.
    var offset = 8.0; // ListView top padding.
    for (var i = 0; i < index; i++) {
      offset += _categoryExtent(_categories[i], _contentWidth);
    }
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _contentWidth = constraints.maxWidth - 16;
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _categories.length,
                    itemExtentBuilder: (index, _) =>
                        _categoryExtent(_categories[index], _contentWidth),
                    itemBuilder: (context, index) {
                      final categoryName = _categories[index];

                      if (categoryName == frequentKey) {
                        return _buildFrequentCategory(context);
                      }

                      final sheetData = EmojisHandler.instance
                          .getSheetDataByName(categoryName);
                      if (sheetData == null) return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 8,
                                left: 4,
                              ),
                              child: Text(
                                categoryName,
                                style: AppText.lowTextStyle.copyWith(
                                  color: AppColors.greyple,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final cellSize =
                                    (constraints.maxWidth - 7 * 4) / 8;
                                final emojiSize = math.max(
                                  1.0,
                                  math.min(30.0, cellSize - 2),
                                );
                                return GridView.builder(
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
                                    final emoji = sheetData.emojis.values
                                        .elementAt(i);
                                    return Center(
                                      child: EmojiWidget(
                                        emoji: emoji,
                                        sheetData: sheetData,
                                        size: emojiSize,
                                        frameInset: 1,
                                        onTap: widget.onTap,
                                        animate: false,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
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
                      key: ValueKey('emoji-category-$categoryName'),
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
                    key: ValueKey('emoji-category-$categoryName'),
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
                                frameInset: 1,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = (constraints.maxWidth - 7 * 4) / 8;
              final emojiSize = math.max(1.0, math.min(30.0, cellSize - 2));
              return GridView.builder(
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

                  final sheetData = EmojisHandler.instance
                      .getSheetDataByCategory(emoji.categoryName ?? '');

                  if (sheetData == null) return const SizedBox.shrink();

                  return Center(
                    child: EmojiWidget(
                      emoji: emoji,
                      sheetData: sheetData,
                      size: emojiSize,
                      frameInset: 1,
                      onTap: widget.onTap,
                      animate: false,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

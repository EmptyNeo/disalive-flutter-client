import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/sticker_content.dart';
import 'package:disalive/domain/models/sticker_pack.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/sticker_item.dart';
import 'package:disalive/presentation/features/stickers/bloc/sticker_bloc.dart';
import 'package:disalive/presentation/widgets/custom_divider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StickersTab extends StatefulWidget {
  final Function(StickerPack pack) onPackLongPress;
  final Function(StickerContent sticker) onTap;

  const StickersTab({
    super.key,
    required this.onPackLongPress,
    required this.onTap,
  });

  @override
  State<StickersTab> createState() => _StickersTabState();
}

class _StickersTabState extends State<StickersTab> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _packKeys = {};

  void _scrollToPack(int packId) {
    final key = _packKeys[packId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.0, // Прокрутить к началу секции (заголовку)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StickerBloc, StickerState>(
      builder: (context, state) {
        if (state is StickerLoading && state is! StickerLoaded) {
          return const Center(child: CupertinoActivityIndicator());
        }

        if (state is StickerLoaded) {
          // 🎯 ФОРМИРУЕМ СПИСОК СЛИВЕРОВ ДИНАМИЧЕСКИ
          final List<Widget> slivers = [];

          for (int i = 0; i < state.packs.length; i++) {
            final pack = state.packs[i];
            final sectionKey = _packKeys.putIfAbsent(
              pack.id,
              () => GlobalKey(),
            );

            // 🎯 SliverMainAxisGroup группирует заголовок и грид в один логический блок,
            // на который можно повесить GlobalKey для прокрутки.
            slivers.add(
              SliverMainAxisGroup(
                key: sectionKey,
                slivers: [
                  // 1. Заголовок пака
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Text(
                        pack.name,
                        style: AppText.lowTextStyle.copyWith(
                          color: AppColors.greyple,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // 2. Истинно ленивый грид стикеров (без shrinkWrap!)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final sticker = pack.attachments![index];
                        return StickerItem(
                          sticker: sticker,
                          maxSize: 80,
                          onTap: () => widget.onTap.call(sticker),
                        );
                      }, childCount: pack.attachments?.length ?? 0),
                    ),
                  ),

                  // 3. Отступ между паками
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 🎯 ОСНОВНОЙ ЛЕНИВЫЙ СПИСОК
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: slivers,
                ),
              ),

              const CustomDivider(),

              // 🎯 УЛЬТРА-КОМПАКТНАЯ ГОРИЗОНТАЛЬНАЯ ПАНЕЛЬ
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: state.packs.length,
                  itemBuilder: (context, index) {
                    final pack = state.packs[index];
                    final firstSticker =
                        (pack.attachments != null &&
                            pack.attachments!.isNotEmpty)
                        ? pack.attachments!.first
                        : null;

                    return GestureDetector(
                      onTap: () => _scrollToPack(pack.id),
                      onLongPress: () => widget.onPackLongPress(pack),
                      child: Container(
                        width: 36,
                        margin: EdgeInsets.only(
                          left: index == 0 ? 0 : 2,
                          right: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.white.withValues(alpha: 0.06),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: firstSticker != null
                              ? StickerItem(sticker: firstSticker, maxSize: 24)
                              : Center(
                                  child: Text(
                                    pack.name.isNotEmpty
                                        ? pack.name[0].toUpperCase()
                                        : '?',
                                    style: AppText.mediumTextStyle.copyWith(
                                      color: AppColors.greyple,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

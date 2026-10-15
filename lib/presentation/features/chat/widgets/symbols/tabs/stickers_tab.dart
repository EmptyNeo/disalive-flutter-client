import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/sticker_content.dart';
import 'package:disalive/domain/models/sticker_pack.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/sticker_item.dart';
import 'package:disalive/presentation/features/stickers/bloc/stickers_pack_bloc.dart';
import 'package:disalive/presentation/features/stickers/widgets/sticker_pack_modal.dart';
import 'package:disalive/presentation/features/stickers/widgets/sticker_pack_view_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/custom_divider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StickersTab extends StatefulWidget {
  final Function(StickerContent sticker) onTap;

  const StickersTab({super.key, required this.onTap});

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
        alignment: 0.0,
      );
    }
  }

  void _showPackActions(BuildContext context, StickerPack pack) {
    final List<ActionItem> actions = [
      ActionItem(
        label: 'Просмотреть набор',
        icon: CupertinoIcons.eye,
        onTap: () {
          StickerPackViewBottomSheet.open(
            context,
            pack: pack,
            onStickerTap: widget.onTap,
          );
        },
      ),
      ActionItem(
        label: 'Удалить из доступных',
        icon: CupertinoIcons.trash,
        color: AppColors.errorRed,
        isDestructive: true,
        onTap: () {
          context.read<StickersPackBloc>().add(RemoveStickerPack(pack.id));
        },
      ),
    ];

    if (pack.isCreator) {
      actions.add(
        ActionItem(
          label: 'Редактировать',
          icon: CupertinoIcons.pencil,
          onTap: () {
            StickerPackModal.open(context, existingPack: pack);
          },
        ),
      );
    }

    ActionBottomSheet.show(context, title: pack.name, actions: actions);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StickersPackBloc, StickersPackState>(
      builder: (context, state) {
        if (state is StickersPackLoading && state is! StickersPackLoaded) {
          return const Center(child: CupertinoActivityIndicator());
        }

        if (state is StickersPackLoaded) {
          // 🎯 1. ФИЛЬТРАЦИЯ: Оставляем только паки, которые пользователь добавил (hasPack == true)
          final filteredPacks = state.packs
              .where((pack) => pack.hasPack)
              .toList();

          // 🎯 2. Если добавленных паков нет, показываем красивую заглушку
          if (filteredPacks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.star, size: 48, color: AppColors.greyple),
                  const SizedBox(height: 16),
                  Text(
                    'У вас пока нет наборов стикеров',
                    style: TextStyle(color: AppColors.greyple, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нажмите +, чтобы добавить новый',
                    style: TextStyle(color: AppColors.greyple, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final List<Widget> slivers = [];

          for (int i = 0; i < filteredPacks.length; i++) {
            final pack = filteredPacks[i];
            final sectionKey = _packKeys.putIfAbsent(
              pack.id,
              () => GlobalKey(),
            );

            slivers.add(
              SliverMainAxisGroup(
                key: sectionKey,
                slivers: [
                  SliverToBoxAdapter(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // нажатие по всей строке, а не только по тексту
                      onTap: () => StickerPackViewBottomSheet.open(
                        context,
                        pack: pack,
                        onStickerTap: widget.onTap,
                      ),
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
                  ),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: slivers,
                ),
              ),
              const CustomDivider(),

              // 🎯 4. НИЖНЯЯ ПАНЕЛЬ ТОЖЕ ИСПОЛЬЗУЕТ filteredPacks
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  // Количество = отфильтрованные паки + 1 кнопка добавления
                  itemCount: filteredPacks.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: () => StickerPackModal.open(context),
                        child: Container(
                          width: 36,
                          margin: const EdgeInsets.only(left: 0, right: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.blurple.withOpacity(0.15),
                            border: Border.all(
                              color: AppColors.blurple.withOpacity(0.3),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.add,
                              color: AppColors.blurple,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }

                    // 🎯 Берем пак из отфильтрованного списка (сдвиг индекса на 1 из-за кнопки "+")
                    final pack = filteredPacks[index - 1];
                    final firstSticker =
                        (pack.attachments != null &&
                            pack.attachments!.isNotEmpty)
                        ? pack.attachments!.first
                        : null;

                    return GestureDetector(
                      onTap: () => _scrollToPack(pack.id),
                      onLongPress: () => _showPackActions(context, pack),
                      child: Container(
                        width: 36,
                        margin: const EdgeInsets.only(left: 2, right: 2),
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

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/sticker_content.dart';
import 'package:disalive/domain/models/sticker_pack.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/sticker_item.dart';
import 'package:disalive/presentation/features/stickers/bloc/stickers_pack_bloc.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StickerPackViewBottomSheet extends StatelessWidget {
  final StickerPack pack;
  final Function(StickerContent) onStickerTap;

  const StickerPackViewBottomSheet({
    super.key,
    required this.pack,
    required this.onStickerTap,
  });

  static Future<void> open(
    BuildContext context, {
    required StickerPack pack,
    required Function(StickerContent) onStickerTap,
  }) {
    final stickersPackBloc = context.read<StickersPackBloc>();
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => BlocProvider.value(
        value: stickersPackBloc,
        child: StickerPackViewBottomSheet(
          pack: pack,
          onStickerTap: onStickerTap,
        ),
      ),
    );
  }

  void _showPackOptions(BuildContext context) {
    final actions = [
      ActionItem(
        label: 'Поделиться',
        icon: CupertinoIcons.square_arrow_up,
        onTap: () {
          // TODO: Реализовать шеринг
          Navigator.pop(context);
        },
      ),
      ActionItem(
        label: 'Копировать ссылку',
        icon: CupertinoIcons.link,
        onTap: () {
          Clipboard.setData(
            ClipboardData(
              text:
                  'https://disalive.ru/addstickers/index.php?packId=${pack.id}',
            ),
          );
          Navigator.pop(context);
          // Можно добавить тост "Ссылка скопирована"
        },
      ),
    ];

    ActionBottomSheet.show(context, title: pack.name, actions: actions);
  }

  @override
  Widget build(BuildContext context) {
    // Вычисляем количество элементов: стикеры + (1 если создатель)
    final stickerCount = pack.attachments?.length ?? 0;
    final totalGridItems = pack.isCreator ? stickerCount + 1 : stickerCount;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.glassPanelTop, AppColors.glassPanelBottom],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🎯 Граббер
                  const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 8),
                    child: Center(child: _GrabberHandle()),
                  ),

                  // 🎯 Заголовок с тремя точками
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            pack.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.highTextStyle.copyWith(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 32,
                          onPressed: () => _showPackOptions(context),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            color: AppColors.greyple,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🎯 Сетка стикеров
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              // 🎯 Если создатель и это первый элемент - рисуем кнопку "+"
                              if (pack.isCreator && index == 0) {
                                return GestureDetector(
                                  onTap: () {
                                    // TODO: Действие при нажатии на "+"
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.blurple.withOpacity(
                                        0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.blurple.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        CupertinoIcons.add,
                                        color: AppColors.blurple,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // 🎯 Иначе рисуем стикер
                              final stickerIndex = pack.isCreator
                                  ? index - 1
                                  : index;
                              final sticker = pack.attachments?[stickerIndex];

                              if (sticker == null) {
                                return const SizedBox.shrink();
                              }

                              return StickerItem(
                                sticker: sticker,
                                maxSize: 80, // Размер как в основном списке
                                onTap: () {
                                  Navigator.pop(context); // Закрываем шторку
                                  onStickerTap(sticker); // Отправляем стикер
                                },
                              );
                            }, childCount: totalGridItems),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      ],
                    ),
                  ),

                  // 🎯 Футер с кнопкой Добавить/Удалить
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(12),
                      color: pack.hasPack
                          ? AppColors.errorRed
                          : AppColors.blurple,
                      onPressed: () {
                        if (pack.hasPack) {
                          context.read<StickersPackBloc>().add(
                            RemoveStickerPack(pack.id),
                          );
                        } else {
                          context.read<StickersPackBloc>().add(
                            AddStickerPack(pack.id),
                          );
                        }
                        Navigator.pop(context);
                      },
                      child: Text(
                        pack.hasPack
                            ? 'Удалить набор из доступных'
                            : 'Добавить набор стикеров',
                        style: AppText.mediumTextStyle.copyWith(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GrabberHandle extends StatelessWidget {
  const _GrabberHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.greyple.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

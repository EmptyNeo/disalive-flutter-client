import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/sticker_content.dart';
import 'package:disalive/domain/models/sticker_pack.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/sticker_item.dart';
import 'package:disalive/presentation/features/stickers/bloc/stickers_pack_bloc.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/media_picker_bottom_sheet.dart'; // поправьте путь
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StickerPackViewBottomSheet extends StatelessWidget {
  /// Начальное состояние пака. Актуальное берётся из блока.
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

  // ───────────────────────── Действия ─────────────────────────

  Future<void> _addStickers(BuildContext context, StickerPack pack) async {
    final bloc = context.read<StickersPackBloc>();

    final files = await MediaPickerBottomSheet.open(
      context: context,
      onlyInitialType: true, // только фото, без переключателя типов
      allowMultiple: true,
      convertToJpg: false, // не ломаем прозрачность PNG/WebP
    );

    if (files == null || files.isEmpty || bloc.isClosed) return;

    for (final file in files) {
      bloc.add(AddStickerContent(packId: pack.id, file: file));
    }
  }

  void _showStickerActions(
    BuildContext context,
    StickerPack pack,
    StickerContent sticker,
  ) {
    HapticFeedback.mediumImpact();

    ActionBottomSheet.show(
      context,
      title: 'Стикер',
      actions: [
        ActionItem(
          label: 'Удалить стикер',
          icon: CupertinoIcons.trash,
          color: AppColors.errorRed,
          isDestructive: true,
          onTap: () {
            context.read<StickersPackBloc>().add(
              RemoveStickerContent(stickerId: sticker.id, packId: pack.id),
            );
          },
        ),
      ],
    );
  }

  void _showPackOptions(BuildContext context, StickerPack pack) {
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
        },
      ),
    ];

    ActionBottomSheet.show(context, title: pack.name, actions: actions);
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StickersPackBloc, StickersPackState>(
      listenWhen: (prev, curr) =>
          curr is StickersPackLoaded &&
          curr.actionFailure != null &&
          !(prev is StickersPackLoaded &&
              prev.actionFailure == curr.actionFailure),
      listener: (context, state) {
        showCupertinoDialog<void>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('Не удалось выполнить действие'),
            content: const Text('Проверьте подключение и попробуйте ещё раз.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
      builder: (context, state) {
        var live = pack;
        var uploading = 0;
        if (state is StickersPackLoaded) {
          live = state.packs.firstWhere(
            (p) => p.id == pack.id,
            orElse: () => pack,
          );
          uploading = state.uploadingIn(pack.id);
        }
        return _buildSheet(context, live, uploading);
      },
    );
  }

  Widget _buildSheet(BuildContext context, StickerPack pack, int uploading) {
    final stickers = pack.attachments ?? const <StickerContent>[];
    final offset = pack.isCreator ? 1 : 0; // кнопка «+» занимает первую ячейку
    final totalGridItems = offset + stickers.length + uploading;
    final showHint = pack.isCreator && stickers.isNotEmpty;

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
                  const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 8),
                    child: Center(child: _GrabberHandle()),
                  ),

                  // Заголовок с тремя точками
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 12, showHint ? 4 : 16),
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
                          onPressed: () => _showPackOptions(context, pack),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            color: AppColors.greyple,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Подсказка про удаление (только создателю)
                  if (showHint)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Удерживайте стикер, чтобы удалить',
                          style: AppText.lowTextStyle.copyWith(
                            color: AppColors.greyple,
                          ),
                        ),
                      ),
                    ),

                  // Сетка стикеров
                  Flexible(
                    fit: FlexFit.loose,
                    child: CustomScrollView(
                      shrinkWrap: true,
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
                              // «+» — первая ячейка у создателя
                              if (pack.isCreator && index == 0) {
                                return _AddStickerTile(
                                  onTap: () => _addStickers(context, pack),
                                );
                              }

                              final i = index - offset;

                              // Заглушки для загружающихся стикеров
                              if (i >= stickers.length) {
                                return const _UploadingTile();
                              }

                              final sticker = stickers[i];
                              final item = StickerItem(
                                sticker: sticker,
                                maxSize: 80,
                                onTap: () {
                                  Navigator.pop(context);
                                  onStickerTap(sticker);
                                },
                              );

                              return KeyedSubtree(
                                key: ValueKey('sticker_${sticker.id}'),
                                child: pack.isCreator
                                    ? GestureDetector(
                                        onLongPress: () => _showStickerActions(
                                          context,
                                          pack,
                                          sticker,
                                        ),
                                        child: item,
                                      )
                                    : item,
                              );
                            }, childCount: totalGridItems),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      ],
                    ),
                  ),

                  // Футер с кнопкой Добавить/Удалить набор
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

class _AddStickerTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddStickerTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blurple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.blurple.withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: Icon(CupertinoIcons.add, color: AppColors.blurple, size: 28),
        ),
      ),
    );
  }
}

class _UploadingTile extends StatelessWidget {
  const _UploadingTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: const Center(child: CupertinoActivityIndicator()),
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

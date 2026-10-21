import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/sticker_content.dart';
import 'package:disalive/domain/repositories/sticker_pack_repository.dart';
import 'package:disalive/presentation/features/stickers/widgets/sticker_pack_view_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';

class StickerPackMessageCard extends StatefulWidget {
  const StickerPackMessageCard({
    super.key,
    required this.packId,
    required this.onStickerTap,
  });

  final int packId;
  final ValueChanged<StickerContent> onStickerTap;

  @override
  State<StickerPackMessageCard> createState() => _StickerPackMessageCardState();
}

class _StickerPackMessageCardState extends State<StickerPackMessageCard> {
  bool _loading = false;

  Future<void> _openPack() async {
    if (_loading) return;
    setState(() => _loading = true);
    final result = await sl<StickerPackRepository>().getById(
      widget.packId,
      0,
      100,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (failure) => CustomToast.open(context: context, message: failure.message),
      (pack) {
        if (pack == null) {
          CustomToast.open(
            context: context,
            message: 'Набор стикеров не найден',
          );
          return;
        }
        StickerPackViewBottomSheet.open(
          context,
          pack: pack,
          onStickerTap: widget.onStickerTap,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => CupertinoButton(
    key: ValueKey('sticker_pack_card_${widget.packId}'),
    padding: const EdgeInsets.all(12),
    onPressed: _loading ? null : _openPack,
    child: Container(
      constraints: const BoxConstraints(minWidth: 190),
      decoration: BoxDecoration(
        color: AppColors.mainBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.square_stack_3d_up_fill,
            color: AppColors.blurple,
            size: 29,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Набор стикеров',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Нажмите для просмотра коллекции стикеров',
                  style: TextStyle(color: AppColors.greyple, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_loading) const CupertinoActivityIndicator(),
        ],
      ),
    ),
  );
}

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/category_channel.dart';
import 'package:flutter/cupertino.dart';

class CategoryChannelItem extends StatelessWidget {
  final CategoryChannel category;
  final bool isCollapsed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onAddChannel;

  const CategoryChannelItem({
    super.key,
    required this.category,
    this.isCollapsed = false,
    this.onTap,
    this.onLongPress,
    this.onAddChannel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: category.name ?? 'Категория',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                onLongPress: onLongPress,
                child: SizedBox(
                  height: 30,
                  child: Row(
                    children: [
                      Icon(
                        isCollapsed
                            ? CupertinoIcons.chevron_right
                            : CupertinoIcons.chevron_down,
                        size: 12,
                        color: AppColors.greyple,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          (category.name ?? 'Без названия').toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.lowTextStyle.copyWith(
                            color: AppColors.greyple,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (onAddChannel != null)
              CupertinoButton(
                key: const ValueKey('add_channel_to_category'),
                padding: const EdgeInsets.all(5),
                minimumSize: const Size(30, 30),
                onPressed: onAddChannel,
                child: Icon(
                  CupertinoIcons.add,
                  size: 17,
                  color: AppColors.greyple,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

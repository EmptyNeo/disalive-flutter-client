// presentation/features/profile/items/badge_item.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/badge.dart';
import 'package:disalive/presentation/widgets/custom_tooltip.dart';
import 'package:flutter/cupertino.dart';

class BadgeItem extends StatelessWidget {
  final BadgeModel badge;
  final double? size;

  const BadgeItem({super.key, this.size = 24, required this.badge});

  @override
  Widget build(BuildContext context) {
    return CustomTooltip(
      title: badge.name?.isNotEmpty == true ? badge.name! : 'Бейдж',
      subtitle: badge.description,
      position: TooltipPosition.top,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: badge.urlPath,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const Center(child: CupertinoActivityIndicator(radius: 8)),
            errorWidget: (context, url, error) => Center(
              child: Icon(
                CupertinoIcons.star_fill,
                color: AppColors.greyple,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

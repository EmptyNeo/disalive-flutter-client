import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/models/media_filter_item.dart';
import 'package:disalive/presentation/widgets/link_opener.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MediaFilterLinkItem extends StatelessWidget {
  const MediaFilterLinkItem({super.key, required this.link});

  final MediaFilterLink link;

  @override
  Widget build(BuildContext context) {
    final image = link.image == null ? null : Domain.transformUrl(link.image);
    final isSvg =
        image != null &&
        (Uri.tryParse(image)?.path.toLowerCase().endsWith('.svg') ?? false);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => LinkOpener.confirmAndOpen(context, link.link),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.actionGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: image == null || image.isEmpty
                    ? _placeholder()
                    : isSvg
                    ? SvgPicture.network(
                        image,
                        fit: BoxFit.cover,
                        placeholderBuilder: (_) => _placeholder(),
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.title?.isNotEmpty == true ? link.title! : link.domain,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.mediumTextStyle.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    link.domain,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.lowTextStyle.copyWith(
                      color: AppColors.greyple,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    link.link,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.lowTextStyle.copyWith(
                      color: AppColors.blurple,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.mainBackground,
    alignment: Alignment.center,
    child: Icon(CupertinoIcons.link, color: AppColors.greyple, size: 26),
  );
}

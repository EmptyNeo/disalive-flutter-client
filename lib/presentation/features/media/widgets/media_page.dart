import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/presentation/features/media/widgets/photo_page.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/spoiler_media_preview.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/video_play_item.dart';
import 'package:flutter/cupertino.dart';

class MediaPage extends StatelessWidget {
  const MediaPage({
    super.key,
    required this.attachment,
    required this.onClose,
    this.isActive = true,
  });

  final FileMessage attachment;
  final VoidCallback onClose;

  final bool isActive;

  @override
  Widget build(BuildContext context) => SpoilerMediaPreview(
    key: ValueKey(attachment.id ?? attachment.urlPath),
    isSpoiler: attachment.isSpoilerFile,
    childBuilder: (context, isRevealed) {
      if (attachment.isSpoilerFile && !isRevealed) {
        final thumbnail = attachment.thumbnailUrlPath;
        return ColoredBox(
          color: CupertinoColors.black,
          child: attachment.isVideoFile && (thumbnail?.isNotEmpty ?? false)
              ? CachedNetworkImage(
                  imageUrl: thumbnail!,
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                )
              : CachedNetworkImage(
                  imageUrl: attachment.urlPath,
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
        );
      }

      if (attachment.isVideoFile) {
        final url = attachment.urlPath;
        return VideoPlayItem(
          source: url,
          isNetwork: url.startsWith('http'),
          isActive: isActive,
          placeholderUrl: attachment.thumbnailUrlPath,
        );
      }

      return PhotoPage(attachment: attachment, onClose: onClose);
    },
  );
}

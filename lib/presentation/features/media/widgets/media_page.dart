import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/presentation/features/media/widgets/photo_page.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/video_play_item.dart'; // поправьте путь
import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';

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
  Widget build(BuildContext context) {
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
  }
}

// lib/presentation/features/message/widgets/media/medias_grid.dart
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/presentation/features/message/widgets/media/grids/audios_grid.dart';
import 'package:disalive/presentation/features/message/widgets/media/grids/files_grid.dart';
import 'package:disalive/presentation/features/message/widgets/media/grids/images_grid.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/sticker_item.dart';
import 'package:disalive/presentation/features/message/widgets/message_status_row.dart';
import 'package:flutter/cupertino.dart';

class MediasGrid extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool hasContentAbove;
  final void Function(int attachmentIndex)? onTapImage;

  final bool showTime;
  final bool isRead;
  final ActionType? isLoading;
  final bool hasError;

  const MediasGrid({
    super.key,
    required this.message,
    required this.isMine,
    required this.hasContentAbove,
    this.onTapImage,
    this.showTime = true,
    this.isRead = false,
    this.isLoading,
    this.hasError = false,
  });

  static bool _isSticker(FileMessage f) => f.isSticker && f.hasValidPath;

  static bool _isImage(FileMessage f) =>
      f.isImageFile && f.hasValidPath && f.isSticker == false;

  static bool _isAudio(FileMessage f) => f.isAudioFile && f.hasValidPath;

  static bool _isOther(FileMessage f) =>
      f.isDefaultFile && !f.isImageFile && !f.isAudioFile && f.hasValidPath;

  static bool hasOnlyImage(Message message) {
    final attachments = message.attachments ?? const [];
    return attachments.any((f) => _isImage(f) || _isSticker(f));
  }

  @override
  Widget build(BuildContext context) {
    final attachments = message.attachments ?? const [];

    final stickers = attachments.where(_isSticker).toList();
    final images = attachments.where(_isImage).toList();
    final audios = attachments.where(_isAudio).toList();
    final files = attachments.where(_isOther).toList();

    final hasOnlyVisualMedias =
        (stickers.isNotEmpty || images.isNotEmpty) &&
        audios.isEmpty &&
        files.isEmpty;
    final showStatusOverlay =
        hasOnlyVisualMedias &&
        (showTime || isLoading != null || hasError || isMine);

    final mediaContent = Column(
      crossAxisAlignment: isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stickers.isNotEmpty) ...[
          if (hasContentAbove) const SizedBox(height: 4),
          StickerItem(
            file: stickers.first,
          ),
          if (images.isNotEmpty || audios.isNotEmpty || files.isNotEmpty)
            const SizedBox(height: 6),
        ],
        if (images.isNotEmpty) ...[
          if (hasContentAbove || stickers.isNotEmpty) const SizedBox(height: 4),
          ImagesGrid(images: images, onTapImage: onTapImage),
          if (audios.isNotEmpty || files.isNotEmpty) const SizedBox(height: 4),
        ],
        if (audios.isNotEmpty) ...[
          if (hasContentAbove || stickers.isNotEmpty || images.isNotEmpty)
            const SizedBox(height: 4),
          AudiosGrid(audios: audios, isMine: isMine),
          if (files.isNotEmpty) const SizedBox(height: 4),
        ],
        if (files.isNotEmpty) ...[
          if (hasContentAbove ||
              stickers.isNotEmpty ||
              images.isNotEmpty ||
              audios.isNotEmpty)
            const SizedBox(height: 4),
          FilesGrid(files: files, isMine: isMine),
        ],
      ],
    );

    if (showStatusOverlay) {
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          mediaContent,
          Positioned(
            bottom: 6, // Небольшой отступ от края, как в Telegram
            right: 6,
            child: MessageStatusRow(
              message: message,
              isMine: isMine,
              isRead: isRead,
              showTime: showTime,
              isLoading: isLoading,
              hasError: hasError,
              isOverlaid: true,
            ),
          ),
        ],
      );
    }

    return mediaContent;
  }
}

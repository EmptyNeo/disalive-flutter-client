// lib/presentation/features/chat/widgets/attachments/attachment_container.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/file_type.dart';
import 'package:disalive/domain/models/ui/action_item.dart';
import 'package:disalive/domain/models/ui/chat_attachment.dart';
import 'package:disalive/presentation/widgets/action_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';

class AttachmentContainer extends StatelessWidget {
  final List<ChatAttachment> attachments;
  final bool hasBanner;
  final Function(ChatAttachment) onRemove;
  final Function(ChatAttachment) onUpdate;

  const AttachmentContainer({
    super.key,
    required this.attachments,
    required this.hasBanner,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.actionGrey,
        borderRadius: BorderRadius.only(
          // 🎯 Логика скруглений по ТЗ
          topLeft: Radius.circular(hasBanner ? 10 : 20),
          topRight: Radius.circular(hasBanner ? 10 : 20),
          bottomLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(20),
        ),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: attachments.map((attachment) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _AttachmentItem(
                attachment: attachment,
                onRemove: () => onRemove(attachment),
                onUpdate: (updated) => onUpdate(updated),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  final ChatAttachment attachment;
  final VoidCallback onRemove;
  final Function(ChatAttachment) onUpdate;

  const _AttachmentItem({
    required this.attachment,
    required this.onRemove,
    required this.onUpdate,
  });

  void _showActions(BuildContext context) {
    ActionBottomSheet.show(
      context,
      actions: [
        ActionItem(
          label: 'Редактировать имя',
          icon: CupertinoIcons.pencil,
          onTap: () => _editName(context),
        ),
        ActionItem(
          label: attachment.isSpoiler ? 'Убрать спойлер' : 'Скрыть под спойлер',
          icon: CupertinoIcons.eye_slash,
          onTap: () {
            attachment.isSpoiler = !attachment.isSpoiler;
            onUpdate(attachment);
          },
        ),
        ActionItem(
          label: 'Удалить',
          icon: CupertinoIcons.trash,
          color: AppColors.errorRed,
          isDestructive: true,
          onTap: onRemove,
        ),
      ],
    );
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: attachment.name);
    final newName = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Новое имя файла'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(controller: controller, autofocus: true),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Сохранить'),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != attachment.name) {
      onUpdate(
        ChatAttachment(
          id: attachment.id,
          file: attachment.file,
          name: newName,
          size: attachment.size,
          unit: attachment.unit,
          fileType: attachment.fileType,
          contentType: attachment.contentType,
          duration: attachment.duration,
          isSpoiler: attachment.isSpoiler,
          isDeleted: attachment.isDeleted,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage =
        attachment.fileType == FileType.image && attachment.file != null;
    final hasUrl = attachment.url != null;
    final sizeText = '${attachment.size} ${attachment.unit}';

    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.glassPanelBottom,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
        ),
        child: Stack(
          children: [
            // 🎯 Контент: Фото или Файл
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isImage && !hasUrl
                  ? Image.file(
                      attachment.file!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                      errorBuilder: (_, __, ___) => _buildFileIcon(),
                    )
                  : hasUrl
                  ? CachedNetworkImage(
                      imageUrl: attachment.url!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildFileIcon(),
                    )
                  : _buildFileIcon(),
            ),

            // 🎯 Индикатор спойлера
            if (attachment.isSpoiler)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.eye_slash,
                      color: CupertinoColors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),

            // 🎯 Кнопка удаления (всегда видна)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: CupertinoColors.white,
                    size: 14,
                  ),
                ),
              ),
            ),

            // 🎯 Информация о файле (для не-фото)
            if (!isImage)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.lowTextStyle.copyWith(
                          color: CupertinoColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            attachment.extension.toUpperCase(),
                            style: AppText.lowTextStyle.copyWith(
                              color: AppColors.blurple,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sizeText,
                            style: AppText.lowTextStyle.copyWith(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    IconData icon = CupertinoIcons.doc;
    if (attachment.fileType == FileType.video) {
      icon = CupertinoIcons.play_circle;
    } else if (attachment.fileType == FileType.audio) {
      icon = CupertinoIcons.waveform;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: AppColors.blurple),
          const SizedBox(height: 8),
          Text(
            attachment.extension.toUpperCase(),
            style: AppText.lowTextStyle.copyWith(
              color: AppColors.greyple,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

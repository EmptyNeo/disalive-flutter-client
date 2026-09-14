// lib/presentation/features/message/widgets/message_status_row.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/action_type.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/presentation/features/message/widgets/media/medias_grid.dart';
import 'package:disalive/presentation/utils/ui/util_date.dart';
import 'package:flutter/cupertino.dart';

class MessageStatusRow extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool isRead;
  final bool showTime;
  final ActionType? isLoading;
  final bool hasError;
  final bool isOverlaid; // 🎯 Новый параметр

  const MessageStatusRow({
    super.key,
    required this.message,
    required this.isMine,
    required this.isRead,
    required this.showTime,
    this.isLoading,
    this.hasError = false,
    this.isOverlaid = false,
  });

  // 🎯 Тень для читаемости поверх картинок/стикеров
  List<Shadow> get _overlayShadow => [
    const Shadow(
      color: CupertinoColors.black,
      offset: Offset(0, 0),
      blurRadius: 8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = isMine || MediasGrid.hasOnlyImage(message)
        ? CupertinoColors.white
        : AppColors.greyple;
    final iconColor = hasError
        ? CupertinoColors.systemRed
        : (isMine ? CupertinoColors.white : AppColors.greyple);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isLoading != null || hasError) ...[
          Icon(
            hasError
                ? CupertinoIcons.exclamationmark_circle
                : _getLoadingIcon(),
            size: 11,
            color: iconColor,
            shadows: isOverlaid ? _overlayShadow : null,
          ),
          const SizedBox(width: 4),
        ],
        if (showTime) ...[
          Text(
            UtilDate.formatTime(message.time),
            style: AppText.lowTextStyle.copyWith(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              shadows: isOverlaid ? _overlayShadow : null,
            ),
          ),
          if (isMine) const SizedBox(width: 4),
        ],
        if (isMine) _buildReadStatus(iconColor),
      ],
    );
  }

  IconData _getLoadingIcon() {
    switch (isLoading) {
      case null:
      case ActionType.create:
      case ActionType.update:
        return CupertinoIcons.time;
      case ActionType.delete:
        return CupertinoIcons.trash;
      case ActionType.block:
        return CupertinoIcons.lock_fill;
    }
  }

  Widget _buildReadStatus(Color color) {
    if (!isRead) {
      return Icon(
        CupertinoIcons.checkmark_alt,
        size: 12,
        color: color,
        shadows: isOverlaid ? _overlayShadow : null,
      );
    }

    return SizedBox(
      width: 18,
      height: 12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            child: Icon(
              CupertinoIcons.checkmark_alt,
              size: 12,
              color: color,
              shadows: isOverlaid ? _overlayShadow : null,
            ),
          ),
          Positioned(
            left: 6,
            child: Icon(
              CupertinoIcons.checkmark_alt,
              size: 12,
              color: color,
              shadows: isOverlaid ? _overlayShadow : null,
            ),
          ),
        ],
      ),
    );
  }
}

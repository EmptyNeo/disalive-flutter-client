import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class VideoThumbnailItem extends StatelessWidget {
  /// Ссылка на само видео (для будущего открытия)
  final String videoSource;

  /// Является ли видео сетевым
  final bool isNetwork;

  final String? thumbnailPath;

  final VoidCallback? onTap;

  /// Используется, только если не заданы одновременно [width] и [height].
  final double aspectRatio;

  /// Равномерное скругление. Игнорируется, если задан [radius].
  final double borderRadius;

  /// Скругление по отдельным углам (для раскладки в сетке).
  final BorderRadius? radius;

  /// Фиксированный размер ячейки. Задавайте оба параметра вместе.
  final double? width;
  final double? height;

  const VideoThumbnailItem({
    super.key,
    required this.videoSource,
    required this.isNetwork,
    this.thumbnailPath,
    this.onTap,
    this.aspectRatio = 1.0,
    this.borderRadius = 12.0,
    this.radius,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final br = radius ?? BorderRadius.circular(borderRadius);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final playSize = side.isFinite ? (side * 0.4).clamp(28.0, 44.0) : 44.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Слой 1: превью или заглушка
            if (thumbnailPath != null && thumbnailPath!.isNotEmpty)
              _buildThumbnail()
            else
              _buildPlaceholder(),

            // Слой 2: лёгкое затемнение для контраста иконки
            Container(color: CupertinoColors.black.withValues(alpha: 0.2)),

            // Слой 3: иконка Play по центру
            Center(
              child: Container(
                width: playSize,
                height: playSize,
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CupertinoColors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.play_fill,
                  color: CupertinoColors.white,
                  size: playSize * 0.55,
                ),
              ),
            ),
          ],
        );
      },
    );

    final Widget body = (width != null && height != null)
        ? SizedBox(width: width, height: height, child: content)
        : AspectRatio(aspectRatio: aspectRatio, child: content);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(borderRadius: br, child: body),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.actionGrey,
      child: Center(
        child: Icon(
          CupertinoIcons.video_camera_solid,
          color: AppColors.greyple,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: thumbnailPath!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.actionGrey,
          child: const Center(child: CupertinoActivityIndicator(radius: 12)),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else {
      return Image.file(
        File(thumbnailPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
  }
}
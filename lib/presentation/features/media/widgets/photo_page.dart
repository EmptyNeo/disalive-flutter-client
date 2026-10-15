import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/domain/models/file_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';

class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key, required this.attachment, required this.onClose});

  final FileMessage attachment;
  final VoidCallback onClose;

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  late final PhotoViewController _photoViewController;
  double? _initialScale;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController();
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PhotoViewGestureDetectorScope(
      axis: Axis.horizontal,
      child: PhotoView.customChild(
        controller: _photoViewController,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3.0,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: const BoxDecoration(
          color: CupertinoColors.transparent,
        ),
        onTapUp: (context, details, controllerValue) {
          final currentScale = controllerValue.scale;
          if (currentScale == null) return;

          _initialScale ??= currentScale;

          if ((currentScale - _initialScale!).abs() < 0.05) {
            widget.onClose();
          }
        },
        child: CachedNetworkImage(
          imageUrl: widget.attachment.urlPath,
          fit: BoxFit.contain,
          cacheKey: widget.attachment.id?.toString(),
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) =>
          const CupertinoActivityIndicator(color: CupertinoColors.white),
          errorWidget: (context, url, error) => const Center(
            child: Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.white,
              size: 40,
            ),
          ),
          maxWidthDiskCache: 2000,
          maxHeightDiskCache: 2000,
        ),
      ),
    );
  }
}
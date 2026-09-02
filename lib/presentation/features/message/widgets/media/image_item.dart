// lib/presentation/features/message/widgets/image_item.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageItem extends StatefulWidget {
  final String pathImage;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ImageItem({
    super.key,
    required this.pathImage,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<ImageItem> createState() => _ImageItemState();
}

class _ImageItemState extends State<ImageItem> {
  static const BorderRadius _defaultBorderRadius = BorderRadius.zero;
  int _retryCount = 0;

  void _retryLoad() {
    setState(() {
      _retryCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? _defaultBorderRadius;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          key: ValueKey('${widget.pathImage}_$_retryCount'),
          imageUrl: widget.pathImage,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppColors.actionGrey,
            child: const Center(child: CupertinoActivityIndicator()),
          ),
          errorWidget: (context, url, error) => GestureDetector(
            onTap: _retryLoad,
            child: Container(
              color: AppColors.actionGrey,
              child: Icon(
                CupertinoIcons.refresh_bold,
                color: AppColors.greyple,
                size: 36,
              ),
            ),
          ),
          cacheKey: '${widget.pathImage}_$_retryCount',
        ),
      ),
    );
  }
}

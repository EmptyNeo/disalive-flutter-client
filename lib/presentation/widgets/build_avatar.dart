import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/constants/assets.dart';
import 'package:disalive/domain/enums/user_status.dart';
import 'package:disalive/presentation/widgets/status_dot.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

class BuildAvatar extends StatefulWidget {
  final String? url;
  final double wh;
  final double size;
  final UserStatus? status;
  final double statusSize;
  final Color? statusBackgroundColor;
  final double statusPosition;
  final bool isBookmark;
  final bool isGroup;

  const BuildAvatar({
    super.key,
    this.url,
    this.isBookmark = false,
    this.isGroup = false,
    required this.wh,
    required this.size,
    this.status,
    this.statusSize = 8,
    this.statusBackgroundColor,
    this.statusPosition = -3,
  });

  @override
  State<BuildAvatar> createState() => _BuildAvatarState();
}

class _BuildAvatarState extends State<BuildAvatar> {
  bool _hasError = false;

  @override
  void didUpdateWidget(covariant BuildAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() {
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = widget.url != null && widget.url!.isNotEmpty;
    final hasDefaultImage =
        (widget.url?.endsWith(AppAssets.defaultUserImage) ?? false) ||
            (widget.url?.endsWith(AppAssets.defaultGroupImage) ?? false);

    final bgColor = widget.statusBackgroundColor ?? AppColors.mainBackground;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: widget.wh,
          height: widget.wh,
          decoration: BoxDecoration(
            color: AppColors.blurple,
            shape: BoxShape.circle,
          ),
          child: ClipOval(child: _buildImage(hasValidUrl, hasDefaultImage)),
        ),
        if (widget.status != null)
          Positioned(
            bottom: widget.statusPosition,
            right: widget.statusPosition,
            child: Container(
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
              child: StatusDot(
                status: widget.status!,
                size: widget.statusSize,
                backgroundColor: bgColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGrey,
      highlightColor: AppColors.mainGrey,
      period: const Duration(milliseconds: 1200),
      child: Container(color: CupertinoColors.white),
    );
  }

  Widget _buildImage(bool hasValidUrl, bool hasDefaultImage) {
    if (widget.isBookmark) {
      return SvgPicture.asset(
        AppAssets.bookmarkIcon,
        width: widget.wh,
        height: widget.wh,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              CupertinoIcons.bookmark_solid,
              color: AppColors.onBlurple,
              size: widget.size,
            ),
          );
        },
      );
    }

    if (!hasValidUrl || hasDefaultImage || _hasError) {
      return defaultAvatar(
        !widget.isGroup
            ? CupertinoIcons.person_solid
            : CupertinoIcons.person_3_fill,
      );
    }

    return CachedNetworkImage(
      imageUrl: Domain.transformUrl(widget.url!),
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildShimmer(),
      errorWidget: (context, url, error) {
        return defaultAvatar(
          !widget.isGroup
              ? CupertinoIcons.person_solid
              : CupertinoIcons.person_3_fill,
        );
      },
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      cacheKey: widget.url,
    );
  }

  Widget defaultAvatar(IconData icon) {
    return Center(
      child: Icon(icon, color: AppColors.onBlurple, size: widget.size),
    );
  }
}

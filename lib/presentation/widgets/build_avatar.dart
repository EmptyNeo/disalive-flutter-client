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
  final double statusPosition;
  final double statusRingWidth;

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
    this.statusPosition = 0,
    this.statusRingWidth = 3,
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

    final hasStatus = widget.status != null;

    final notchCenter = Offset(
      widget.wh - widget.statusPosition - widget.statusSize / 2,
      widget.wh - widget.statusPosition - widget.statusSize / 2,
    );
    final notchRadius = widget.statusSize / 2 + widget.statusRingWidth;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: hasStatus
              ? _AvatarNotchClipper(center: notchCenter, radius: notchRadius)
              : const _CircleClipper(),
          child: Container(
            width: widget.wh,
            height: widget.wh,
            color: AppColors.blurple,
            child: _buildImage(hasValidUrl, hasDefaultImage),
          ),
        ),
        if (hasStatus)
          Positioned(
            bottom: widget.statusPosition,
            right: widget.statusPosition,
            // Без обёртки-контейнера с цветом фона: зазор вокруг кружка —
            // это вырезанная дырка выше, а не что-то, что рисует сам
            // StatusDot, поэтому его собственный фон делаем прозрачным.
            child: StatusDot(
              status: widget.status ?? UserStatus.offline,
              size: widget.statusSize,
              backgroundColor: CupertinoColors.transparent,
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
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );
  }

  Widget defaultAvatar(IconData icon) {
    return Center(
      child: Icon(icon, color: AppColors.onBlurple, size: widget.size),
    );
  }
}

class _AvatarNotchClipper extends CustomClipper<Path> {
  const _AvatarNotchClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) {
    final avatarPath = Path()
      ..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    final notchPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    return Path.combine(PathOperation.difference, avatarPath, notchPath);
  }

  @override
  bool shouldReclip(covariant _AvatarNotchClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}

/// Обычная круглая обрезка — когда статуса нет, "укус" вырезать не из чего.
class _CircleClipper extends CustomClipper<Path> {
  const _CircleClipper();

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

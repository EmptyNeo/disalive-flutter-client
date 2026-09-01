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

  const BuildAvatar({
    super.key,
    this.url,
    this.isBookmark = false,
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
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void didUpdateWidget(covariant BuildAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = widget.url != null && widget.url!.isNotEmpty;
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
          child: ClipOval(child: _buildImage(hasValidUrl)),
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

  // Раньше base/highlight брались с alpha 0.2/0.5 — Shimmer.fromColors красит
  // через ShaderMask, и итоговая альфа пикселя определяется альфой самого
  // градиента, а не непрозрачностью child. С такими прозрачными цветами
  // сквозь шиммер просвечивал фон аватарки (blurple), и вместо переливов
  // получалось блёклое серое пятно. Теперь оба цвета полностью непрозрачны и
  // контрастны друг другу — виден чёткий бегущий блик.
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGrey,
      highlightColor: AppColors.mainGrey,
      period: const Duration(milliseconds: 1200),
      child: Container(color: CupertinoColors.white),
    );
  }

  Widget _buildImage(bool hasValidUrl) {
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

    if (!hasValidUrl || _hasError) {
      return Center(
        child: Icon(
          CupertinoIcons.person_solid,
          color: AppColors.onBlurple,
          size: widget.size,
        ),
      );
    }

    // Раньше здесь был ещё один шиммер поверх того, что уже возвращает
    // loadingBuilder ниже (if (_isLoading) _buildShimmer() в Stack) — два
    // независимых, рассинхронизированных по фазе шиммера накладывались друг
    // на друга и гасили эффект перелива до однородно-серого пятна. Теперь
    // шиммер рисуется только один раз — самим loadingBuilder.
    return Image.network(
      Domain.transformUrl(widget.url!),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isLoading) {
              setState(() {
                _isLoading = false;
              });
            }
          });
          return child;
        }
        return _buildShimmer();
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasError) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
        });
        return Center(
          child: Icon(
            CupertinoIcons.person_solid,
            color: AppColors.onBlurple,
            size: widget.size,
          ),
        );
      },
    );
  }
}
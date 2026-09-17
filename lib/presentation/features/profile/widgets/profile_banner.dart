import 'dart:io'; // 🎯 Убедись, что импорт есть
import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';

class ProfileBanner extends StatelessWidget {
  final Color? backgroundColor;
  final String? backgroundImageUrl;
  final File? backgroundImageFile;
  final double height;

  const ProfileBanner({
    super.key,
    this.backgroundColor,
    this.backgroundImageUrl,
    this.backgroundImageFile,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidFile = backgroundImageFile != null;
    final hasValidUrl =
        backgroundImageUrl != null && backgroundImageUrl!.isNotEmpty;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: hasValidFile
          ? Image.file(
              backgroundImageFile!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallback(),
            )
          : (hasValidUrl
                ? CachedNetworkImage(
                    imageUrl: backgroundImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildShimmer(),
                    errorWidget: (context, url, error) => _buildFallback(),
                  )
                : _buildFallback()),
    );
  }

  Widget _buildShimmer() {
    final isDark = AppColors.isDarkMode();
    final baseColor = isDark ? AppColors.actionGrey : AppColors.lightGrey;
    final highlightColor = isDark
        ? AppColors.mainGrey
        : AppColors.white.withValues(alpha: 0.6);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: baseColor,
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor ?? AppColors.mainBackground,
    );
  }
}

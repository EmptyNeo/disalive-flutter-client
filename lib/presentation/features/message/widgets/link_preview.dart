// presentation/features/message/widgets/link_preview.dart
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/link_data.dart';
import 'package:disalive/presentation/widgets/link_opener.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

/// Превью ссылки в сообщении — акцентная полоска слева + сайт/заголовок/
/// описание (тот же паттерн, что у AnswerPreview), плюс картинка или
/// заглушка-плеер снизу, если у ссылки есть image/video.
///
/// Тап открывает [LinkOpener.confirmAndOpen] — переход только после
/// подтверждения, случайный тап никуда не уводит.
class LinkPreview extends StatelessWidget {
  const LinkPreview({super.key, required this.link, this.isMine = false});

  final LinkData link;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final accentColor = isMine ? AppColors.onBlurple : AppColors.blurple;
    final backgroundColor = (isMine ? AppColors.onBlurple : AppColors.white)
        .withValues(alpha: 0.08);
    final titleColor = isMine ? AppColors.onBlurple : AppColors.white;
    final mutedColor = (isMine ? AppColors.onBlurple : AppColors.white)
        .withValues(alpha: 0.7);

    final hasSiteName = (link.siteName ?? '').isNotEmpty;
    final hasTitle = (link.title ?? '').isNotEmpty;
    final hasDescription = (link.description ?? '').isNotEmpty;
    final hasMedia = link.hasImage || link.hasVideo;

    return GestureDetector(
      onTap: link.url == null
          ? null
          : () => LinkOpener.confirmAndOpen(context, link.url!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasSiteName)
                        Text(
                          link.siteName!.toUpperCase(),
                          style: AppText.lowTextStyle.copyWith(
                            color: mutedColor,
                            fontSize: 10,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (hasTitle) ...[
                        if (hasSiteName) const SizedBox(height: 2),
                        Text(
                          link.title!,
                          style: AppText.mediumTextStyle.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (hasDescription) ...[
                        const SizedBox(height: 2),
                        Text(
                          link.description!,
                          style: AppText.lowTextStyle.copyWith(
                            color: mutedColor,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (hasMedia) ...[
                        if (hasSiteName || hasTitle || hasDescription)
                          const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _LinkMedia(link: link),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkMedia extends StatefulWidget {
  const _LinkMedia({required this.link});

  final LinkData link;

  @override
  State<_LinkMedia> createState() => _LinkMediaState();
}

class _LinkMediaState extends State<_LinkMedia> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final link = widget.link;

    // Есть только video (без image-превью с бэка) — сам плеер сюда не
    // встраиваем, просто индикатор, что по ссылке видео.
    if (!link.hasImage) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        color: AppColors.actionGrey,
        child: Icon(
          CupertinoIcons.play_circle_fill,
          color: AppColors.iconGrey,
          size: 32,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasError)
            Container(
              color: AppColors.actionGrey,
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.photo,
                color: AppColors.iconGrey,
                size: 28,
              ),
            )
          else if (_isSvg(link.image!))
            _buildSvgImage(link.image!)
          else
            _buildRasterImage(link.image!),
          // Картинка у видео-ссылки — это постер, оверлей с play явно
          // отличает такое превью от обычной картиночной ссылки.
          if (link.hasVideo)
            Container(
              color: CupertinoColors.black.withValues(alpha: 0.25),
              alignment: Alignment.center,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.play_fill,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isSvg(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    return path.toLowerCase().endsWith('.svg');
  }

  Widget _buildRasterImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _shimmer();
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasError) setState(() => _hasError = true);
        });
        return Container(color: AppColors.actionGrey);
      },
    );
  }

  // SVG-превью обычно логотип/иконка сайта, а не фотография — cover будет
  // обрезать его как попало, поэтому contain + сплошная подложка под
  // прозрачный фон самой SVG.
  Widget _buildSvgImage(String url) {
    return Container(
      color: AppColors.mainBackground,
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: SvgPicture.network(
        url,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => _shimmer(),
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasError) setState(() => _hasError = true);
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _shimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGrey,
      highlightColor: AppColors.mainGrey,
      child: Container(color: CupertinoColors.white),
    );
  }
}